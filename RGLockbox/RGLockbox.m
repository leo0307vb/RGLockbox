/* Copyright (c) 01/27/2016, Ryan Dignard
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

#import "RGLockbox.h"
#import "RGDefines.h"
#import <Security/Security.h>

static NSString* const _sIsoFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";

static NSString* rg_bundle_identifier(void) {
    static NSString* _sBundleIdentifier;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sBundleIdentifier = [NSBundle bundleForClass:[RGLockbox self]].infoDictionary[(id)kCFBundleIdentifierKey];
    });
    return _sBundleIdentifier;
}

@implementation RGLockbox

+ (instancetype) manager {
    static dispatch_once_t onceToken;
    static id _sManager;
    dispatch_once(&onceToken, ^{
        _sManager = [self new];
    });
    return _sManager;
}

+ (RG_PREFIX_NONNULL dispatch_queue_t) keychainQueue {
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("RGLockbox-Sync", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

- (RG_PREFIX_NONNULL instancetype) init {
    return [self initWithNamespace:nil accessibility:nil];
}

- (RG_PREFIX_NONNULL instancetype) initWithNamespace:(RG_PREFIX_NULLABLE NSString*)namespace accessibility:(RG_PREFIX_NULLABLE CFStringRef)accessibility {
    self = [super init];
    if (self) {
        self->_namespace = namespace ?: rg_bundle_identifier();
        self->_itemAccessibility = accessibility ?: kSecAttrAccessibleAfterFirstUnlock;
    }
    return self;
}

- (RG_PREFIX_NULLABLE NSData*) objectForKey:(RG_PREFIX_NONNULL NSString*)key {
    NSString* hierarchyKey = self.namespace ? [NSString stringWithFormat:@"%@.%@", self.namespace, key] : key;
    NSDictionary* query = @{ (id)kSecClass : (id)kSecClassGenericPassword, (id)kSecAttrService : hierarchyKey, (id)kSecReturnData : @YES };
    CFTypeRef data = nil;
    SecItemCopyMatching((__bridge CFDictionaryRef)query, &data);
    return (__bridge_transfer NSData*)data;
}

- (void) setObject:(RG_PREFIX_NULLABLE NSData*)object forKey:(RG_PREFIX_NONNULL NSString*)key {
    return [self setObject:object forKey:key withAccessibility:self.itemAccessibility];
}

- (void) setObject:(RG_PREFIX_NULLABLE NSData*)object forKey:(RG_PREFIX_NONNULL NSString*)key withAccessibility:(RG_PREFIX_NONNULL CFStringRef)accessibility {
    NSString* hierarchyKey = self.namespace ? [NSString stringWithFormat:@"%@.%@", self.namespace, key] : key;
    NSMutableDictionary* query = [@{ (id)kSecClass : (id)kSecClassGenericPassword, (id)kSecAttrService : hierarchyKey } mutableCopy];
    if (object) { /* Add or Update... */
        NSDictionary* payload = @{ (id)kSecValueData : object, (id)kSecAttrAccessible : (__bridge id)accessibility };
        [query addEntriesFromDictionary:payload];
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
        if (status == errSecDuplicateItem) { /* Duplicate, only update possible */
            status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)payload);
        }
        return status == errSecSuccess;
    } /* Not Add or Update, must be delete */
    return SecItemDelete((__bridge CFDictionaryRef)query) == errSecSuccess;
}

@end
