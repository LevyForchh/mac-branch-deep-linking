//
//  TestBedUIDeepLinkDataTest.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/3/20.
//  Copyright © 2020 Branch. All rights reserved.
//

#import "TestBedUITest.h"
#import "TestBedUIUtils.h"

//static NSString *shortURL;
//void *kMyKVOContext = (void*)&kMyKVOContext;
//extern void *kMyKVOContext;
XCTestExpectation *expectationForAppLaunch;
//id observer;

@interface TestBedUIDeepLinkDataTest : TestBedUITest

@end

@implementation TestBedUIDeepLinkDataTest

extern void *kMyKVOContext;

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDeepLink {
    
    __block NSDictionary *linkData;
    __block NSString *shortURL;
    
    XCTWaiterResult result = [self launchAppAndWaitForSessionStart];
    
    [XCTContext runActivityNamed:@"CreateShortLink" block:^(id<XCTActivity> activity) {
        if (result == XCTWaiterResultCompleted) {
            
            shortURL = [self createShortLink];
            
            XCTAssertTrue([[self serverRequestString] containsString:@"/v1/url"]);
            
            NSDictionary *serverRequestDictionary = [ TestBedUIUtils dictionaryFromString:[self serverRequestString]];
            linkData = [serverRequestDictionary objectForKey:@"data"];
            
           // NSDictionary *serverResponseDictionary = [ TestBedUIUtils dictionaryFromString:[self serverResponseString]];
           // XCTAssertNotNil([serverResponseDictionary valueForKey:@"identity_id"]);
            //XCTAssertNotNil([serverResponseDictionary valueForKey:@"device_fingerprint_id"]);
            [self terminateApp];
        }
        else {
            XCTFail("App Launch / Session Start Failed.");
        }
    }];

    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    [safariApp launch];
    [safariApp activate];
    XCUIElement *element = [safariApp.windows.textFields elementBoundByIndex:0];
    [element click];
    sleep(1.0);
    [element typeText:shortURL];
    [element typeKey:XCUIKeyboardKeyEnter
       modifierFlags:XCUIKeyModifierNone];  // TODO Check for return key also
    sleep(1.0);
    [[[safariApp descendantsMatchingType:XCUIElementTypeToggle] elementBoundByIndex:1 ] click];

    expectationForAppLaunch = [self expectationWithDescription:@"testShortLinks"];

    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew // maybe | NSKeyValueObservingOptionInitial
                                       context:kMyKVOContext];
  //  NSLog(@"%@" , [safariApp debugDescription]);
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
    
    
    
    NSMutableString *deepLinkDataString = [[NSMutableString alloc] initWithData:[NSData dataWithContentsOfFile:@"/tmp/deepLinkData.txt"]  encoding:NSUTF8StringEncoding];
    
    [deepLinkDataString replaceOccurrencesOfString:@" = " withString:@" : " options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@";\n" withString:@",\n" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    [deepLinkDataString replaceOccurrencesOfString:@"website" withString:@"\"website\"" options:0 range:NSMakeRange(0 , [deepLinkDataString length])];
    
    NSError *error;
    NSDictionary *deepLinkDataDictionary = [NSJSONSerialization JSONObjectWithData: [ deepLinkDataString dataUsingEncoding:NSUTF8StringEncoding ] options:0 error:&error];
    
    for ( NSString* key in linkData){
        XCTAssertNotNil(deepLinkDataDictionary[key]);
        XCTAssertEqualObjects(linkData[key], deepLinkDataDictionary[key]);
        NSLog(@" Key is Equql ========== %@" , key);
    }
}


- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (context != kMyKVOContext)
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if ([keyPath isEqualToString:@"runningApplications"])
    {
        for (NSRunningApplication * application in NSWorkspace.sharedWorkspace.runningApplications) {
                if ([application.bundleIdentifier isEqualToString:@"io.branch.sdk.TestBed-Mac"]) {
                    [[NSWorkspace sharedWorkspace] removeObserver:self forKeyPath:@"runningApplications"];
                    [expectationForAppLaunch fulfill];
                    [application terminate];
                    break;
                }
            }
    }
}
@end