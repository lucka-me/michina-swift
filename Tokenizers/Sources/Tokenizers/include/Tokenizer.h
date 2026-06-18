//
//  Tokenizer.h
//  Tokenizers
//
//  Created by Lucka on 2026-06-18.
//

#import <Foundation/Foundation.h>

#import "Encoding.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_SENDABLE
@interface Tokenizer : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initFromPath:(NSString*)path
                                error:(NSError**)error NS_DESIGNATED_INITIALIZER;

- (nullable Encoding*)encodeText:(NSString*)text
                           error:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
