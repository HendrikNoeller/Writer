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

@property (nonatomic) NSMutableArray *lines; //Stores every line as an element. Multiple lines of stuff
@property (nonatomic) NSMutableArray *changedIndices; //Stores every line that needs to be formatted according to the type

//Parsing methods
- (ContinousFountainParser*)initWithString:(NSString*)string;
- (void)parseChangeInRange:(NSRange)range withString:(NSString*)string;

//Convenience Methods for Testing
- (NSString*)stringAtLine:(NSUInteger)line;
- (LineType)typeAtLine:(NSUInteger)line;
- (NSUInteger)positionAtLine:(NSUInteger)line;

//Convenience Methods for Outlineview data
- (NSUInteger)numberOfTopLevelitems; //Returns the number of synopses or headings before the first section + the number of sections
- (NSArray*)topLevelItems; //Returns all synopses or headings before the first section and then all sections
- (NSUInteger)numberOfChildrenForLine:(Line*)sectionLine;
- (NSArray*)childrenForLine:(Line*)sectionLine;

- (NSString*)toString;
@end
