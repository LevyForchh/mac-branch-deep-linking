/**
 @file          BNCPersistence.m
 @package       Branch
 @brief         Persists a smallish (< 1mb?) set of data between app runs.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCPersistence.h"
#import "BNCLog.h"

#pragma mark BNCPersistence

@implementation BNCPersistence

+ (NSError*_Nullable) saveDataNamed:(NSString*)name data:(NSData*)data {
    NSError *error = nil;
    NSURL *url = BNCURLForBranchDataDirectory();
    url = [url URLByAppendingPathComponent:name isDirectory:NO];
    NSURL*urlPath = [url URLByDeletingLastPathComponent];
    [[NSFileManager defaultManager]
        createDirectoryAtURL:urlPath
        withIntermediateDirectories:YES
        attributes:nil
        error:&error];
    if (error) BNCLogError(@"Can't create directory: %@.", error);
    error = nil;
    [data writeToURL:url options:NSDataWritingAtomic error:&error];
    if (error) BNCLogError(@"Failed to write '%@': %@.", url, error);
    return error;
}

+ (NSData*_Nullable) loadDataNamed:(NSString*)name {
    NSError *error = nil;
    NSURL *url = BNCURLForBranchDataDirectory();
    url = [url URLByAppendingPathComponent:name isDirectory:NO];
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (error) {
        BNCLogWarning(@"Failed to read '%@': %@.", url, error);
    }
    return data;
}

+ (NSError*_Nullable) removeDataNamed:(NSString *)name {
    NSError *error = nil;
    NSURL *url = BNCURLForBranchDataDirectory();
    url = [url URLByAppendingPathComponent:name isDirectory:NO];
    [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    if (error) {
        if (error.code == NSFileNoSuchFileError)
            error = nil;
        else
            BNCLogWarning(@"Failed to remove '%@': %@.", url, error);
    }
    return error;
}

+ (id<NSSecureCoding>) unarchiveObjectNamed:(NSString*)name {
    id<NSSecureCoding> object = nil;
    @try {
        NSData* data = [self loadDataNamed:name];
        if (!data) return nil;
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch(id e) {
        BNCLogError(@"Can't unarchive '%@': %@.", name, e);
        object = nil;
    }
    return object;
}

+ (NSError*) archiveObject:(id<NSSecureCoding>)object named:(NSString*)name {
    NSError*error = nil;
    @try {
        NSData*data = [NSKeyedArchiver archivedDataWithRootObject:object];
        error = [BNCPersistence saveDataNamed:name data:data];
    }
    @catch (id exception) {
        if (error) {
            BNCLogDebugSDK(@"Exception: %@.", exception);
        } else {
            NSString*s = [NSString stringWithFormat:@"Exception %@.", exception];
            error = [NSError errorWithDomain:NSCocoaErrorDomain
                code:NSFileWriteUnknownError userInfo:@{NSLocalizedDescriptionKey: s}];
        }
    }
    if (error) BNCLogError(@"Can't archive '%@': %@.", name, error);
    return error;
}

@end

#pragma mark - BNCURLForBranchDataDirectory

NSURL* _Null_unspecified BNCCreateDirectoryForBranchURLWithSearchPath_Unthreaded(NSSearchPathDirectory directory) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *URLs = [fileManager URLsForDirectory:directory inDomains:NSUserDomainMask | NSLocalDomainMask];

    for (NSURL *URL in URLs) {
        NSError *error = nil;
        NSURL *branchURL = [[NSURL alloc] initWithString:@"io.branch" relativeToURL:URL];
        BOOL success =
            [fileManager
                createDirectoryAtURL:branchURL
                withIntermediateDirectories:YES
                attributes:nil
                error:&error];
        if (success) {
            return branchURL;
        } else  {
            NSLog(@"[branch.io] Info: CreateBranchURL failed: %@ URL: %@.", error, branchURL);
        }
    }
    return nil;
}

NSURL* _Nonnull BNCURLForBranchDirectory_Unthreaded() {
    NSArray *kSearchDirectories = @[
        @(NSApplicationSupportDirectory),
        @(NSLibraryDirectory),
        @(NSCachesDirectory),
        @(NSDocumentDirectory),
    ];

    for (NSNumber *directory in kSearchDirectories) {
        NSSearchPathDirectory directoryValue = [directory unsignedLongValue];
        NSURL *URL = BNCCreateDirectoryForBranchURLWithSearchPath_Unthreaded(directoryValue);
        if (URL) return URL;
    }

    //  Worst case backup plan:
    NSString *path = [@"~/Library/io.branch" stringByExpandingTildeInPath];
    NSURL *branchURL = [NSURL fileURLWithPath:path isDirectory:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL success =
        [fileManager
            createDirectoryAtURL:branchURL
            withIntermediateDirectories:YES
            attributes:nil
            error:&error];
    if (!success) {
        NSLog(@"[io.branch] Error: Worst case CreateBranchURL error was: %@ URL: %@.", error, branchURL);
    }
    return branchURL;
}

NSURL* _Nonnull BNCURLForBranchDataDirectory() {
    static NSURL *urlForBranchDirectory = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        urlForBranchDirectory = BNCURLForBranchDirectory_Unthreaded();
    });
    return urlForBranchDirectory;
}