//
//  Tokenizer.mm
//  Tokenizers
//
//  Created by Lucka on 2026-06-18.
//

#import "Tokenizer.h"

#import "TokenizerError.h"

#include <optional>

#include "tokenizers-bridge.rs.h"

NS_ASSUME_NONNULL_BEGIN

static NSInteger const kTokenizerErrorCode = 1;

@implementation Tokenizer {
    std::optional<rust::Box<tokenizers_bridge::rust::Tokenizer>> _box;
}

- (nullable instancetype)initFromPath:(NSString*)path
                                error:(NSError**)error {
    if ((self = [super init]) == nil) {
      return nil;
    }
    
    const rust::Str rustPath(path.UTF8String);
    try {
        _box = tokenizers_bridge::rust::Tokenizer::from_file(rustPath);
        return self;
    } CATCH_TOKENIZER(error)
}

- (Boolean)enableFixingLength:(size_t)length
             withPaddingToken:(NSString*)token
                        error:(NSError**)error {
    const rust::Str rustToken(token.UTF8String);
    try {
        return (*_box)->enable_fixing_length(length, rustToken);
    } CATCH_TOKENIZER_RETURN(error, false)
}

- (nullable Encoding *)encodeText:(NSString*)text
                            error:(NSError**)error {
    const rust::Str rustText(text.UTF8String);
    try {
        const auto rustEncoding = (*_box)->encode(rustText);
        
        NSMutableArray<NSNumber*>* ids = [
            NSMutableArray arrayWithCapacity:rustEncoding.ids.size()
        ];
        for (const auto element : rustEncoding.ids) {
            NSNumber* number = [NSNumber numberWithUnsignedInt:element];
            [ids addObject:number];
        }
        
        NSMutableArray<NSNumber*>* attentionMask = [
            NSMutableArray arrayWithCapacity:rustEncoding.attention_mask.size()
        ];
        for (const auto element : rustEncoding.attention_mask) {
            NSNumber* number = [NSNumber numberWithUnsignedInt:element];
            [attentionMask addObject:number];
        }
        
        Encoding* encoding = [[Encoding alloc] init];
        encoding.ids = ids;
        encoding.attentionMask = attentionMask;
        
        return encoding;
    } CATCH_TOKENIZER(error)
}

@end

NS_ASSUME_NONNULL_END
