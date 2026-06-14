//
//  RetinaFaceSidecar.swift
//  Magearna
//
//  Created by Lucka on 2026-05-21.
//

struct RetinaFaceSidecar : Sendable {
    let supportLandmarks: Bool  // use_kps
    let groupsCount: Int        // fmc
    let stridePerGroup: [ Int ] // feat_stride_fpn
    let anchorsPerPoint: Int    // num_anchors
    
    init(outputNamesCount: Int) {
        switch outputNamesCount {
        case 6:
            self.supportLandmarks = false
            self.groupsCount = 3
            self.stridePerGroup = [ 8, 16, 32 ]
            self.anchorsPerPoint = 2
        case 9:
            self.supportLandmarks = true
            self.groupsCount = 3
            self.stridePerGroup = [ 8, 16, 32 ]
            self.anchorsPerPoint = 2
        case 10:
            self.supportLandmarks = false
            self.groupsCount = 5
            self.stridePerGroup = [ 8, 16, 32, 64, 128 ]
            self.anchorsPerPoint = 1
        case 15:
            self.supportLandmarks = true
            self.groupsCount = 5
            self.stridePerGroup = [ 8, 16, 32, 64, 128 ]
            self.anchorsPerPoint = 1
        default:
            fatalError("Unsupported output names count: \(outputNamesCount)")
        }
    }
}
