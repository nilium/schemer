//
//  QScheme.m
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QScheme.h"
#import "QSchemeRule.h"
#import "NSFilters.h"
#import "NSColor+QHexColor.h"
#import "aux.h"


static
BOOL
isBaseRuleDictionary(NSDictionary *rule);

static
NSDictionary *
getBaseRuleDictionary(NSArray *settings);

static
NSArray *
getRulesDictionaries(NSArray *settings);


static id (^const copyRuleBlock)(id) = ^(id obj) {
  return [obj copy];
};


static id (^const convertPListToRuleBlock)(id) = ^id(id obj) {
  return [[QSchemeRule alloc] initWithPropertyList:obj];
};


static BOOL (^const indexOfBaseRulesDictTest)(id, NSUInteger, BOOL *) =
  ^(id obj, NSUInteger index, BOOL *stop) {
    return isBaseRuleDictionary(obj);
  };


static
BOOL
isBaseRuleDictionary(NSDictionary *rule)
{
  return
       [rule isKindOfClass:[NSDictionary class]]
    && 1 == [rule count]
    && nil != rule[@"settings"];
}


static
NSDictionary *
getBaseRuleDictionary(NSArray *settings)
{
  const NSUInteger index =
    [settings indexOfObjectPassingTest:indexOfBaseRulesDictTest];

  if (index != NSNotFound) {
    return settings[index];
  }

  return nil;
}


static
NSArray *
getRulesDictionaries(NSArray *settings)
{
  return [settings rejectedBy:^BOOL(id obj) {
    return isBaseRuleDictionary(obj);
  }];
}


@interface QScheme ()

@property (copy, readwrite) NSUUID *uuid;

@end


@implementation QScheme

- (id)init
{
  if ((self = [super init])) {
    NSColor *black = [NSColor.blackColor forScheme];

    self.foregroundColor = black;
    self.backgroundColor = [NSColor.whiteColor forScheme];

    self.lineHighlightColor =
      [[NSColor colorWithWhite:0.0f alpha:0.07f] forScheme];

    self.selectionColor =
      [[NSColor selectedTextBackgroundColor] forScheme];
    self.selectionBorderColor =
      [self.selectionColor colorWithAlphaComponent:0.0f];
    self.inactiveSelectionColor =
      [self.selectionColor colorWithAlphaComponent:0.5f];

    self.invisiblesColor =
      [[NSColor colorWithWhite:0.75f alpha:1.0f] forScheme];

    self.caretColor = black;

    self.uuid = [NSUUID UUID];
    self.rules = @[];
  }

  return self;
}


- (id)initWithPropertyList:(NSDictionary *)plist
{
  static dispatch_queue_t conversion_queue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    conversion_queue = dispatch_queue_create(
      "net.spifftastic.schemer.convert",
      DISPATCH_QUEUE_CONCURRENT
      );
  });

  if ((self = [self init])) {
    NSDictionary *baseRules = getBaseRuleDictionary(plist[@"settings"]);
    NSArray *rules = getRulesDictionaries(plist[@"settings"]);

    if (!baseRules || !baseRules[@"settings"]) {
      return nil;
    }

    NSDictionary *settings = baseRules[@"settings"];

    self.foregroundColor =
      [colorSetting(settings, @"foreground", self.foregroundColor)
       colorWithAlphaComponent:1.0];

    self.backgroundColor =
      [colorSetting(settings, @"background", self.backgroundColor)
       colorWithAlphaComponent:1.0];

    self.lineHighlightColor =
      colorSetting(settings, @"lineHighlight", self.lineHighlightColor);

    self.selectionColor =
      colorSetting(settings, @"selection", self.selectionColor);

    self.selectionBorderColor =
      colorSetting(settings, @"selectionBorder", self.selectionBorderColor);

    self.inactiveSelectionColor =
      colorSetting(settings, @"inactiveSelection", self.inactiveSelectionColor);

    self.invisiblesColor =
      colorSetting(settings, @"invisibles", self.invisiblesColor);

    self.caretColor = colorSetting(settings, @"caret", self.caretColor);

    self.rules =
      [rules mappedTo:convertPListToRuleBlock queue:conversion_queue stride:16];

    NSString *uuidString = baseRules[@"uuid"];
    if (uuidString) {
      NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
      if (uuid) {
        self.uuid = uuid;
      } else {
        NSLog(@"%@ is an invalid UUID, generating a new one.", uuidString);
      }
    }
  }

  return self;
}


- (id)initWithScheme:(QScheme *)scheme
{
  if ((self = [self init]) && scheme) {
    self.foregroundColor        = scheme.foregroundColor;
    self.backgroundColor        = scheme.backgroundColor;
    self.lineHighlightColor     = scheme.lineHighlightColor;
    self.selectionColor         = scheme.selectionColor;
    self.selectionBorderColor   = scheme.selectionBorderColor;
    self.inactiveSelectionColor = scheme.inactiveSelectionColor;
    self.invisiblesColor        = scheme.invisiblesColor;
    self.caretColor             = scheme.caretColor;
    self.rules                  = [scheme.rules mappedTo:copyRuleBlock];
    self.uuid                   = scheme.uuid;
  }
  return self;
}


- (id)copyWithZone:(NSZone *)zone
{
  return [[self.class alloc] initWithScheme:self];
}


- (NSDictionary *)toPropertyList
{
  NSMutableDictionary *plist = [NSMutableDictionary new];

  plist[@"uuid"] = self.uuid.UUIDString;

  NSMutableArray *baseRules =
    [NSMutableArray arrayWithCapacity:[self.rules count] + 1];

  NSMutableDictionary *settings =
    [NSMutableDictionary dictionaryWithCapacity:8];

  settings[@"foreground"] = [self.foregroundColor toHexColorString];
  settings[@"background"] =
    [[self.backgroundColor colorWithAlphaComponent:1.0] toHexColorString];

  putColorIfVisible(settings, @"lineHighlight", self.lineHighlightColor);
  putColorIfVisible(settings, @"selection", self.selectionColor);
  putColorIfVisible(settings, @"selectionBorder", self.selectionBorderColor);
  putColorIfVisible(settings, @"inactiveSelection", self.inactiveSelectionColor);
  putColorIfVisible(settings, @"invisibles", self.invisiblesColor);
  putColorIfVisible(settings, @"caret", self.caretColor);

  [baseRules addObject:@{ @"settings": settings }];

  for (QSchemeRule *rule in self.rules) {
    [baseRules addObject:[rule toPropertyList]];
  }

  plist[@"settings"] = baseRules;

  return plist;
}

@end
