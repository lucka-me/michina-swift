//
//  TokenizerError.mm
//  Tokenizers
//
//  Created by Lucka on 2026-06-18.
//

#import "TokenizerError.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const kTokenizerErrorDomain = @"Tokenizer";

void SaveExceptionToError(const std::exception& exception, NSError** error) {
    NSString* description = [NSString stringWithCString:exception.what()
                                               encoding:NSUTF8StringEncoding];
    *error = [NSError errorWithDomain:kTokenizerErrorDomain
                                 code:TokenizerErrorCode::TokenizerErrorCodeRustError
                             userInfo:@{ NSLocalizedDescriptionKey : description }];
}

void SaveRustErrorToError(const rust::Error& rustError, NSError** error) {
    NSString* description = [NSString stringWithCString:rustError.what()
                                               encoding:NSUTF8StringEncoding];
    *error = [NSError errorWithDomain:kTokenizerErrorDomain
                                 code:TokenizerErrorCode::TokenizerErrorCodeException
                             userInfo:@{ NSLocalizedDescriptionKey : description }];
}

NS_ASSUME_NONNULL_END
