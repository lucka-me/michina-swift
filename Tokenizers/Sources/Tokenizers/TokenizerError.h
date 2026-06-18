//
//  TokenizerError.h
//  Tokenizers
//
//  Created by Lucka on 2026-06-18.
//

#import <Foundation/Foundation.h>

#include "bridge.rs.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TokenizerErrorCode) {
    TokenizerErrorCodeRustError,
    TokenizerErrorCodeException,
};

void SaveExceptionToError(const std::exception& exception, NSError** error);
void SaveRustErrorToError(const rust::Error& rustError, NSError** error);

#define CATCH_TOKENIZER(error)                  \
    catch (const rust::Error& rustError) {      \
        SaveRustErrorToError(rustError, error); \
        return nil;                             \
    } catch (const std::exception& exception) { \
        SaveExceptionToError(exception, error); \
        return nil;                             \
    }

NS_ASSUME_NONNULL_END
