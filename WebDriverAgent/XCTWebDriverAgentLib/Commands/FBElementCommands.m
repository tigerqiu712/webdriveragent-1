/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementCommands.h"

#import <libkern/OSAtomic.h>

#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBXCTElementCache.h"
#import "FBXCTSession.h"
#import "XCTestDriver.h"
#import "XCUIApplication.h"
#import "XCUICoordinate.h"
#import "XCUIDevice.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBScrolling.h"
#import "XCUIElement+UIAClassMapping.h"
#import "XCUIElement+WebDriverAttributes.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"
#import "FBWDALogger.h"

@interface FBElementCommands ()
@end

@implementation FBElementCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/element/:id/enabled"] respondWithTarget:self action:@selector(handleGetEnabled:)],
    [[FBRoute GET:@"/element/:id/rect"] respondWithTarget:self action:@selector(handleGetRect:)],
    [[FBRoute GET:@"/element/:id/size"] respondWithTarget:self action:@selector(handleGetSize:)],
    [[FBRoute GET:@"/element/:id/location"] respondWithTarget:self action:@selector(handleGetLocation:)],
    [[FBRoute GET:@"/element/:id/location_in_view"] respondWithTarget:self action:@selector(handleGetLocationInView:)],
    [[FBRoute GET:@"/element/:id/attribute/:name"] respondWithTarget:self action:@selector(handleGetAttribute:)],
    [[FBRoute GET:@"/element/:id/text"] respondWithTarget:self action:@selector(handleGetText:)],
    [[FBRoute GET:@"/element/:id/displayed"] respondWithTarget:self action:@selector(handleGetDisplayed:)],
    [[FBRoute GET:@"/element/:id/accessible"] respondWithTarget:self action:@selector(handleGetAccessible:)],
    [[FBRoute GET:@"/element/:id/name"] respondWithTarget:self action:@selector(handleGetName:)],
    [[FBRoute POST:@"/element/:id/value"] respondWithTarget:self action:@selector(handleGetValue:)],
    [[FBRoute POST:@"/element/:id/click"] respondWithTarget:self action:@selector(handleClick:)],
    [[FBRoute POST:@"/element/:id/clear"] respondWithTarget:self action:@selector(handleClear:)],
    [[FBRoute POST:@"/uiaElement/:id/doubleTap"] respondWithTarget:self action:@selector(handleDoubleTap:)],
    [[FBRoute POST:@"/uiaElement/:id/touchAndHold"] respondWithTarget:self action:@selector(handleTouchAndHold:)],
    [[FBRoute POST:@"/uiaElement/:id/scroll"] respondWithTarget:self action:@selector(handleScroll:)],
    [[FBRoute POST:@"/uiaElement/:id/value"] respondWithTarget:self action:@selector(handleGetUIAElementValue:)],
    [[FBRoute POST:@"/element/:id/swipe"] respondWithTarget:self action:@selector(handleDrag:)],
    [[FBRoute POST:@"/tap/:id"] respondWithTarget:self action:@selector(handleTap:)],
    [[FBRoute POST:@"/keys"] respondWithTarget:self action:@selector(handleKeys:)],
    [[FBRoute GET:@"/window/:id/size"] respondWithTarget:self action:@selector(handleGetWindowSize:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetEnabled:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  BOOL isEnabled = element.isWDEnabled;
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, isEnabled ? @YES : @NO);
}

+ (id<FBResponsePayload>)handleGetRect:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.wdRect);
}

+ (id<FBResponsePayload>)handleGetSize:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.wdSize);
}

+ (id<FBResponsePayload>)handleGetLocation:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.wdLocation);
}

+ (id<FBResponsePayload>)handleGetLocationInView:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  NSError *error;
  if ([element scrollToVisibleWithError:&error]) {
    return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.wdLocation);
  }
  return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
}

+ (id<FBResponsePayload>)handleGetAttribute:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  id attributeValue = [element valueForWDAttributeName:request.parameters[@"name"]];
  attributeValue = attributeValue ?: [NSNull null];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, attributeValue);
}

+ (id<FBResponsePayload>)handleGetText:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  id text;
  if ([element elementType] == XCUIElementTypeStaticText || [element elementType] == XCUIElementTypeButton) {
    text = [element wdLabel];
  } else {
    text = [element wdValue];
  }
  text = text ?: [NSNull null];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, text);
}

+ (id<FBResponsePayload>)handleGetDisplayed:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  BOOL isVisible = element.isWDVisible;
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, isVisible ? @YES : @NO);
}

+ (id<FBResponsePayload>)handleGetAccessible:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, @(element.isWDAccessible));
}

+ (id<FBResponsePayload>)handleGetName:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  id type = [element wdType];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, type);
}

+ (id<FBResponsePayload>)handleGetValue:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  if (!element.hasKeyboardFocus) {
    [element tap];
  }
  NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
  NSError *error = nil;
  if (![self.class typeText:textToType error:&error]) {
    return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
  }
  return FBResponseDictionaryWithElementID(elementID);
}

+ (id<FBResponsePayload>)handleClick:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  [element tap];
  return FBResponseDictionaryWithElementID(elementID);
}

+ (id<FBResponsePayload>)handleClear:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  if (!element.hasKeyboardFocus) {
    [element tap];
  }
  NSMutableString *textToType = @"".mutableCopy;
  for (NSUInteger i = 0 ; i < [element.value length] ; i++) {
    [textToType appendString:@"\b"];
  }
  NSError *error;
  if (![self.class typeText:textToType error:&error]) {
    return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
  }
  return FBResponseDictionaryWithElementID(elementID);
}

+ (id<FBResponsePayload>)handleDoubleTap:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  [element doubleTap];
  return FBResponseDictionaryWithOK();
}

+ (id<FBResponsePayload>)handleTouchAndHold:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  [element pressForDuration:[request.arguments[@"duration"] doubleValue]];
  return FBResponseDictionaryWithOK();
}

+ (id<FBResponsePayload>)handleScroll:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];

  // Using presence of arguments as a way to convey control flow seems like a pretty bad idea but it's
  // what ios-driver did and sadly, we must copy them.
  NSString *const name = request.arguments[@"name"];
  if (name) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"wdName == %@", name];
    XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate] allElementsBoundByIndex] lastObject];
    return [self.class handleScrollElementToVisible:childElement withRequest:request];
  }

  NSString *const direction = request.arguments[@"direction"];
  if (direction) {
    if ([direction isEqualToString:@"up"]) {
      [element scrollUp];
    } else if ([direction isEqualToString:@"down"]) {
      [element scrollDown];
    } else if ([direction isEqualToString:@"left"]) {
      [element scrollLeft];
    } else if ([direction isEqualToString:@"right"]) {
      [element scrollRight];
    }
    return FBResponseDictionaryWithOK();
  }

  NSString *const predicateString = request.arguments[@"predicateString"];
  if (predicateString) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
    XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate] allElementsBoundByIndex] lastObject];
    return [self.class handleScrollElementToVisible:childElement withRequest:request];
  }

  if (request.arguments[@"toVisible"]) {
    return [self.class handleScrollElementToVisible:element withRequest:request];
  }
  return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, @{});
}

+ (id<FBResponsePayload>)handleGetUIAElementValue:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  NSString *value = request.arguments[@"value"];
  if (!value) {
    return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, @"Missing value parameter");
  }
  [element adjustToPickerWheelValue:value];
  return FBResponseDictionaryWithOK();
}

+ (id<FBResponsePayload>)handleDrag:(FBRouteRequest *)request
{
    FBXCTSession *session = (FBXCTSession *)request.session;
    CGVector startPoint = CGVectorMake([request.arguments[@"startX"] doubleValue], [request.arguments[@"startY"] doubleValue]);
    CGVector endPoint = CGVectorMake([request.arguments[@"endX"] doubleValue], [request.arguments[@"endY"] doubleValue]);
    CGFloat duration = [request.arguments[@"duration"] doubleValue]/1000;
    XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:session.application normalizedOffset:CGVectorMake(0, 0)];
    XCUICoordinate *endCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:endPoint];
    XCUICoordinate *startCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:startPoint];
    [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
    return FBResponseDictionaryWithOK();
}

+ (id<FBResponsePayload>)handleTap:(FBRouteRequest *)request
{
  FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
  FBXCTSession *session = (FBXCTSession *)request.session;
  CGFloat x = [request.arguments[@"x"] doubleValue];
  CGFloat y = [request.arguments[@"y"] doubleValue];
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  if (element != nil) {
    CGRect rect = element.frame;
    x += rect.origin.x;
    y += rect.origin.y;
  }
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:session.application normalizedOffset:CGVectorMake(0, 0)];
  XCUICoordinate *tapCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:CGVectorMake(x, y)];
  [tapCoordinate tap];
  return FBResponseDictionaryWithOK();
}

+ (id<FBResponsePayload>)handleKeys:(FBRouteRequest *)request
{
  NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
  NSError *error;
  if (![self.class typeText:textToType error:&error]) {
    return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
  }
  return FBResponseDictionaryWithOK();
}

+ (id<FBResponsePayload>)handleGetWindowSize:(FBRouteRequest *)request
{
  FBXCTSession *session = (FBXCTSession *)request.session;
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, session.application.wdRect[@"size"]);
}


#pragma mark - Helpers

/*!
 * Types a string into the element. The element or a descendant must have keyboard focus; otherwise an
 * error is raised.
 *
 * This API discards any modifiers set in the current context by +performWithKeyModifiers:block: so that
 * it strictly interprets the provided text. To input keys with modifier flags, use  -typeKey:modifierFlags:.
 */
+ (BOOL)typeText:(NSString *)text error:(NSError **)error
{
  __block volatile uint32_t didFinishTyping = 0;
  __block BOOL didSucceed = NO;
  __block NSError *innerError;
  [[XCTestDriver sharedTestDriver].managerProxy _XCT_sendString:text completion:^(NSError *typingError){
    didSucceed = (typingError == nil);
    innerError = typingError;
    OSAtomicOr32Barrier(1, &didFinishTyping);
  }];
  while (!didFinishTyping) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  if (error) {
    *error = innerError;
  }
  return didSucceed;
}

+ (id<FBResponsePayload>)handleScrollElementToVisible:(XCUIElement *)element withRequest:(FBRouteRequest *)request
{
  NSError *error;
  if ([element scrollToVisibleWithError:&error]) {
    return FBResponseDictionaryWithOK();
  } else {
    return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
  }
}

@end
