//
//  Service.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

import CoreImage
import Hummingbird
import Logging
import Magearna
import ServiceLifecycle
import UnixSignals

@Observable
@MainActor
final class WebService {
    private(set) var errors: [ ApplicationError ] = [ ]
    private(set) var status = Status.paused
    
    private(set) var clientMetrics: [ WebClientMetric ] = [ ]
    
    private let applicationLogger = Logger(label: "WebService.Application")
    private let inference = InferenceService.default
    private let settings = WebServiceSettings.shared
    
    @ObservationIgnored
    private var serviceGroup: ServiceGroup? = nil
    
    nonisolated private let reportContinuation: AsyncStream<WebClientMetric.Report>.Continuation
    
    private init() {
        let (reportStream, reportContinuation) = AsyncStream.makeStream(
            of: WebClientMetric.Report.self,
            bufferingPolicy: .unbounded
        )
        self.reportContinuation = reportContinuation
        Task(name: "WebService.Report", priority: .background) {
            if self.settings.startWhenInitialized {
                try? await start()
            }
            await self.handle(reportStream: reportStream)
        }
    }
}

extension WebService {
    enum Status {
        case paused
        case running(port: Int)
        
        var isRunning: Bool {
            switch self {
            case .running(_): true
            default: false
            }
        }
    }
    
    struct ApplicationError: Identifiable {
        let id = UUID()
        let date = Date.now
        let error: Error
        
        var description: String {
            if
                let typedError = error as? LocalizedError,
                let description = typedError.errorDescription
            {
                description
            } else {
                error.localizedDescription
            }
        }
    }
}

extension WebService {
    static let shared: WebService = .init()
}

extension WebService {
    func start() async throws {
        guard serviceGroup == nil else {
            return
        }
        
        let router = Router(context: WebServiceRequestContext.self)
        router.get("", use: Self.handleRoot(request:context:))
        router.get("ping", use: handlePing(request:context:))
        router.post("predict", use: handlePredict(request:context:))
        
        let host = "0.0.0.0"
        let port = settings.port
        let logger = self.applicationLogger
        
        Task.detached(
            name: "WebService.Application",
            priority: .high
        ) { [ weak self ] in
            let application = Application(
                router: router,
                configuration: .init(
                    address: .hostname(host, port: port)
                ),
                logger: logger
            )
            let serviceGroup = ServiceGroup(
                configuration: .init(
                    services: [ application ],
                    gracefulShutdownSignals: [ .sigterm, .sigint ],
                    logger: logger
                )
            )
            await MainActor.run {
                self?.serviceGroup = serviceGroup
            }
            
            do {
                try await serviceGroup.run()
            } catch {
                await self?.handle(error: .init(error: error))
            }
        }
        
        self.status = .running(port: port)
    }
    
    func stop() async {
        defer {
            serviceGroup = nil
            self.status = .paused
        }
        
        await serviceGroup?.triggerGracefulShutdown()
    }
    
    func clearErrors() {
        self.errors.removeAll()
    }
}

extension WebService {
    func terminate() {
        self.reportContinuation.finish()
    }
}

fileprivate extension WebService {
    func handle(error: ApplicationError) async {
        self.errors.append(error)
        await stop()
    }
}

fileprivate extension WebService {
    nonisolated static func handleRoot(
        request: Request,
        context: WebServiceRequestContext
    ) -> [ String : String ] {
        [ "message": "Michina" ]
    }
}

fileprivate extension WebService {
    nonisolated func handlePredict(
        request: Request,
        context: WebServiceRequestContext
    ) async throws -> PredictResponse {
        let requestContent = try await request.decode(
            as: PredictRequest.self,
            context: context
        )
        
        reportContinuation.yield(
            .predict(
                from: context.findClientAddress(with: request),
                in: requestContent.category,
                contentLength: request.contentLength
            )
        )
        
        let response: PredictResponse
        switch requestContent {
        case .facialRecognition(let input):
            response = .facialRecognition(
                output: try await InferenceService.default.run(
                    FacialRecognitionInferencePipeline.self,
                    input: input
                ),
                imageSize: input.image.extent.size
            )
        case .visualSearch(let input):
            response = .visualSearch(
                output: try await InferenceService.default.run(
                    VisualSearchInferencePipeline.self,
                    input: input
                ),
                imageSize: input.image.extent.size
            )
        case .textualSearch(let input):
            response = .textualSearch(
                output: try await InferenceService.default.run(
                    TextualSearchInferencePipeline.self,
                    input: input
                ),
            )
        case .characterRecognition(let input):
            response = .characterRecognition(
                output: try await InferenceService.default.run(
                    CharacterRecognitionInferencePipeline.self,
                    input: input
                ),
                imageSize: input.image.extent.size
            )
        }
        
        return response
    }
}

fileprivate extension WebService {
    nonisolated func handlePing(
        request: Request,
        context: WebServiceRequestContext
    ) async throws -> String {
        reportContinuation.yield(
            .ping(from: context.findClientAddress(with: request))
        )
        return "pong"
    }
}

fileprivate extension WebService {
    func handle(reportStream: AsyncStream<WebClientMetric.Report>) async {
        for await report in reportStream {
            if let index = clientMetrics.lastIndex(where: { $0.address == report.address }) {
                clientMetrics[index].record(report: report)
            } else {
                clientMetrics.append(.record(report: report))
            }
        }
    }
}

fileprivate extension Request {
    var contentLength: Int64 {
        if
            let field = self.headers[values: .contentLength].first,
            let value = Int64(field)
        {
            value
        } else {
            0
        }
    }
}
