//
//  UnitedRequestDecoder.swift
//  Michina
//
//  Created by Lucka on 2026-06-12.
//

import Foundation
import Hummingbird
import MultipartKit

struct UnitedRequestDecoder : RequestDecoder {
    func decode<T : Decodable>(
        _ type: T.Type,
        from request: Request,
        context: some RequestContext
    ) async throws -> T {
        if
            let contentType = request.headers[values: .contentType].first,
            let mediaType = MediaType(from: contentType),
            mediaType.isType(.multipartForm)
        {
            guard
                let parameter = mediaType.parameter,
                parameter.name == "boundary"
            else {
                throw HTTPError(
                    .badRequest,
                    message: "The boundary of Multipart Form Data is missing."
                )
            }
            
            return try FormDataDecoder()
                .decode(
                    type,
                    from: try await request.body.collect(upTo: context.maxUploadSize),
                    boundary: parameter.value
                )
        } else {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try await decoder.decode(type, from: request, context: context)
        }
    }
}
