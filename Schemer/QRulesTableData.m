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

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  // Used to return the actual data for the column, but it's not really being used, this just
  // returns nil, now, since doing otherwise would cause the tableView to try to set the object
  // value of the controls to something and that's not pretty.
  return nil;
}

@end
