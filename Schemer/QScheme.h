/*===========================================================================
  Copyright (c) 2014, Noel Cower.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
===========================================================================*/

/* QScheme.h - Noel Cower */

#import <Foundation/Foundation.h>


@class NSDocument;


@interface QScheme : NSObject <NSCopying>

// Colors
@property (copy) NSColor *foregroundColor;
@property (copy) NSColor *backgroundColor;
@property (copy) NSColor *lineHighlightColor;
@property (copy) NSColor *selectionColor;
@property (copy) NSColor *selectionBorderColor;
@property (copy) NSColor *inactiveSelectionColor;
@property (copy) NSColor *invisiblesColor;
@property (copy) NSColor *caretColor;
@property (copy) NSColor *gutterFGColor;
@property (copy) NSColor *gutterBGColor;
@property (copy) NSColor *findHiliteFGColor;
@property (copy) NSColor *findHiliteBGColor;

@property (copy) NSArray *rules; // <QSchemeRule>

@property (copy, readonly) NSUUID *uuid;

- (id)init;
- (id)initWithPropertyList:(NSDictionary *)plist;
- (id)initWithScheme:(QScheme *)scheme;

- (NSDictionary *)toPropertyList;

@end
