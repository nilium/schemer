//
//  QRulesTableData.m
//  Schemer
//
//  Created by Noel Cower on 01/27/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QRulesTableData.h"
#import "QScheme.h"
#import "QSchemeRule.h"


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

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  QSchemeRule *rule = _scheme.rules[row];
  return [rule valueForKey:tableColumn.identifier];
}

@end
