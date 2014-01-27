//
//  QScheme.h
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import <Foundation/Foundation.h>


@class NSDocument;


@interface QScheme : NSObject <NSCopying>

@property (copy) NSString *name;

// Colors
@property (copy) NSColor *foregroundColor;
@property (copy) NSColor *backgroundColor;
@property (copy) NSColor *lineHighlightColor;
@property (copy) NSColor *selectionColor;
@property (copy) NSColor *selectionBorderColor;
@property (copy) NSColor *inactiveSelectionColor;
@property (copy) NSColor *invisiblesColor;
@property (copy) NSColor *caretColor;

@property (copy) NSArray *rules; // <QSchemeRule>

@property (copy, readonly) NSUUID *uuid;

- (id)initWithDocument:(NSDocument *)doc;
- (id)initWithPropertyList:(NSDictionary *)plist document:(NSDocument *)doc;

- (NSDictionary *)toPropertyList;

@end
