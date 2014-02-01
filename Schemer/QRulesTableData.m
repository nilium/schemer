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

/* QRulesTableData.m - Noel Cower */

#import "QRulesTableData.h"
#import "QScheme.h"
#import "QSchemeRule.h"
#import "NSFilters.h"


NSString *const QRulePasteType = @"net.spifftastic.schemer.paste.rule";


@implementation QRulesTableData {
  QScheme *_scheme;
}


- (id)initWithScheme:(QScheme *)scheme
{
  if ((self = [self init])) {
    _scheme = scheme;
  }
  return self;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [_scheme.rules count];
}


- (id)
                  tableView:(NSTableView *)tableView
  objectValueForTableColumn:(NSTableColumn *)tableColumn
                        row:(NSInteger)row
{
  // Used to return the actual data for the column, but it's not really being
  // used, this just returns nil, now, since doing otherwise would cause the
  // tableView to try to set the object value of the controls to something and
  // that's not pretty.
  return nil;
}


#pragma mark Drag / drop support

- (BOOL)
      tableView:(NSTableView *)tableView
     acceptDrop:(id<NSDraggingInfo>)info
            row:(NSInteger)row
  dropOperation:(NSTableViewDropOperation)dropOperation
{
  if (dropOperation == NSTableViewDropOn) {
    return NO;
  }

  NSUInteger mask = [info draggingSourceOperationMask];
  id source = [info draggingSource];
  NSPasteboard *paste = [info draggingPasteboard];

  NSArray *items =
    [[paste readObjectsForClasses:@[[NSPasteboardItem class]] options:nil]
     mappedTo:^(id obj) {
       return [obj propertyListForType:QRulePasteType];
     }];

  NSMutableIndexSet *indices = [NSMutableIndexSet new];

  if (source == tableView && mask & NSDragOperationMove) {
    for (NSDictionary *item in items) {
      NSInteger itemRow = [item[@"row"] integerValue];
      [indices addIndex:itemRow];
      if (itemRow < row) {
        row -= 1;
      }
    }
  }

  NSMutableArray *rules = [_scheme.rules mutableCopy];
  [rules removeObjectsAtIndexes:indices];
  NSArray *newRules = [items mappedTo:^id(NSDictionary *item) {
    return [[QSchemeRule alloc] initWithPropertyList:item[@"rule"]];
  }];

  NSInteger count = (NSInteger)[rules count];
  if (row >= count) {
    [rules addObjectsFromArray:newRules];
  } else {
    NSRange range = NSMakeRange(row, [newRules count]);
    NSIndexSet *newRuleIndices = [NSIndexSet indexSetWithIndexesInRange:range];

    [rules insertObjects:newRules atIndexes:newRuleIndices];
  }

  _scheme.rules = rules;

  return YES;
}


- (NSDragOperation)
              tableView:(NSTableView *)tableView
           validateDrop:(id<NSDraggingInfo>)info
            proposedRow:(NSInteger)row
  proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
  if (dropOperation != NSTableViewDropAbove) {
    [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
  }

  if (row >= 0 && row <= [_scheme.rules count]) {
    id source = [info draggingSource];
    NSUInteger mask = [info draggingSourceOperationMask];

    if (   mask == NSDragOperationCopy
        || (source != tableView && (mask & NSDragOperationCopy))) {
      return NSDragOperationCopy;
    }

    if (mask & NSDragOperationMove && source == tableView) {
      return NSDragOperationMove;
    }
  }

  return NSDragOperationNone;
}


- (id<NSPasteboardWriting>)
               tableView:(NSTableView *)tableView
  pasteboardWriterForRow:(NSInteger)row
{
  NSPasteboardItem *item = [NSPasteboardItem new];
  NSDictionary *rulePList = @{
    @"row":   @(row),
    @"rule":  [_scheme.rules[row] toPropertyList]
  };
  [item setPropertyList:rulePList forType:QRulePasteType];
  return item;
}


@end
