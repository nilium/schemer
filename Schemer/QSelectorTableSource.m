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

#import "QSelectorTableSource.h"
#import "QSchemeRule.h"


@implementation QSelectorTableSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  if (self.rule) {
    return self.rule.selectors.count;
  }

  return 0;
}


- (id)
                  tableView:(NSTableView *)tableView
  objectValueForTableColumn:(NSTableColumn *)tableColumn
                        row:(NSInteger)row
{
  if (self.rule) {
    NSArray *selectors = self.rule.selectors;
    if (row >= 0 && row < [selectors count]) {
      return selectors[row];
    }
  }

  return nil;
}


- (void)
       tableView:(NSTableView *)tableView
  setObjectValue:(id)object
  forTableColumn:(NSTableColumn *)tableColumn
             row:(NSInteger)row
{
  if (object && self.rule) {
    NSString *selector = nil;

    if ([object isKindOfClass:[NSString class]]) {
      selector = [object copy];
    } else {
      selector = [object description];
    }

    NSMutableArray *selectors = [self.rule.selectors mutableCopy];
    selectors[row] = selector;
    self.rule.selectors = selectors;
  }
}

@end
