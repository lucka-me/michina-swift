//
//  Encoding.h
//  Tokenizers
//
//  Created by Lucka on 2026-06-18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Encoding : NSObject

@property(nonatomic) NSArray<NSNumber*>* ids;

@property(nonatomic) NSArray<NSNumber*>* attentionMask;

@end

NS_ASSUME_NONNULL_END
