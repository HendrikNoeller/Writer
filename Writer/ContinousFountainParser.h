//
//  ContinousFountainParser.h
//  Writer
//
//  Created by Hendrik Noeller on 01.04.16.
//  Copyright © 2016 Hendrik Noeller. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Line.h"

@interface ContinousFountainParser : NSObject

- (ContinousFountainParser*)initWithString:(NSString*)string;

- (void)parseChange:(NSNotification*)change;
- (void)applyFormatChangesInTextView:(NSTextView*)textView;

- (LineType)typeAtLine:(NSUInteger)line;

- (NSString*)toString;
@end
