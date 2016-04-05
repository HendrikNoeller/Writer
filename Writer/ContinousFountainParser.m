//
//  ContinousFountainParser.m
//  Writer
//
//  Created by Hendrik Noeller on 01.04.16.
//  Copyright © 2016 Hendrik Noeller. All rights reserved.
//

#import "ContinousFountainParser.h"
#import "Line.h"
#import "NSString+Whitespace.h"
#import "NSMutableIndexSet+Lowest.h"

@implementation ContinousFountainParser

#pragma mark - Parsing

#pragma mark Bulk Parsing

- (ContinousFountainParser*)initWithString:(NSString*)string
{
    self = [super init];
    
    if (self) {
        _lines = [[NSMutableArray alloc] init];
        _changedIndices = [[NSMutableArray alloc] init];
        [self parseText:string];
    }
    
    return self;
}

- (void)parseText:(NSString*)text
{
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    
    NSUInteger positon = 0; //To track at which position every line begins
    
    for (NSString *rawLine in lines) {
        NSInteger index = [self.lines count];
        Line* line = [[Line alloc] initWithString:rawLine type:0 position:positon];
        [self parseTypeAndFormattingForLine:line atIndex:index];
        
        //Add to lines array
        [self.lines addObject:line];
        //Mark change in buffered changes
        [self.changedIndices addObject:@(index)];
        
        positon += [rawLine length] + 1; // +1 for newline character
    }
}

#pragma mark Contionous Parsing

- (void)parseChangeInRange:(NSRange)range withString:(NSString*)string
{
    NSMutableIndexSet *changedIndices = [[NSMutableIndexSet alloc] init];
    if (range.length == 0) { //Addition
        for (int i = 0; i < string.length; i++) {
            NSString* character = [string substringWithRange:NSMakeRange(i, 1)];
            [changedIndices addIndexes:[self parseCharacterAdded:character
                                                      atPosition:range.location+i]];
        }
    } else if ([string length] == 0) { //Removal
        for (int i = 0; i < range.length; i++) {
            [changedIndices addIndexes:[self parseCharacterRemovedAtPosition:range.location]];
        }
    } else { //Replacement
        [self parseChangeInRange:range withString:@""]; //First remove
        [self parseChangeInRange:NSMakeRange(range.location, 0)
                      withString:string]; // Then add
    }
    
    [self correctParsesInLines:changedIndices];
}

- (NSMutableIndexSet*)parseCharacterAdded:(NSString*)character atPosition:(NSUInteger)position
{
    NSUInteger lineIndex = [self lineIndexAtPosition:position];
    Line* line = self.lines[lineIndex];
    NSUInteger indexInLine = position - line.position;
    if ([character isEqualToString:@"\n"]) {
        NSString* cutOffString;
        if (indexInLine == [line.string length]) {
            cutOffString = @"";
        } else {
            cutOffString = [line.string substringFromIndex:indexInLine];
            line.string = [line.string substringToIndex:indexInLine];
        }
        
        LineType newLineType = [self parseLineType:cutOffString
                                       atIndex:lineIndex+1];
        Line* newLine = [[Line alloc] initWithString:cutOffString
                                                type:newLineType
                                            position:position+1];
        [self.lines insertObject:newLine atIndex:lineIndex+1];
        
        [self incrementLinePositionsFromIndex:lineIndex+2 amount:1];
        
        return [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(lineIndex, 2)];
    } else {
        NSArray* pieces = @[[line.string substringToIndex:indexInLine],
                            character,
                            [line.string substringFromIndex:indexInLine]];
        
        line.string = [pieces componentsJoinedByString:@""];
        [self incrementLinePositionsFromIndex:lineIndex+1 amount:1];
        
        return [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(lineIndex, 1)];
    }
}

- (NSMutableIndexSet*)parseCharacterRemovedAtPosition:(NSUInteger)position
{
    NSUInteger lineIndex = [self lineIndexAtPosition:position];
    Line* line = self.lines[lineIndex];
    NSUInteger indexInLine = position - line.position;
    
    if (indexInLine == [line.string length]) {
        //Get next line an put together
        if (lineIndex == [self.lines count] - 1) {
            return nil; //Removed newline at end of document without there being an empty line - should never happen but be sure...
        }
        Line* nextLine = self.lines[lineIndex+1];
        line.string = [line.string stringByAppendingString:nextLine.string];
        [self.lines removeObjectAtIndex:lineIndex+1];
        [self decrementLinePositionsFromIndex:lineIndex+1 amount:1];
        
        return [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(lineIndex, 1)];
    } else {
        NSArray* pieces = @[[line.string substringToIndex:indexInLine],
                            [line.string substringFromIndex:indexInLine+1]];
        
        line.string = [pieces componentsJoinedByString:@""];
        [self decrementLinePositionsFromIndex:lineIndex+1 amount:1];
        
        return [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(lineIndex, 1)];
    }
}

- (NSUInteger)lineIndexAtPosition:(NSUInteger)position
{
    for (int i = 0; i < [self.lines count]; i++) {
        Line* line = self.lines[i];
        
        if (line.position > position) {
            return i-1;
        }
    }
    return [self.lines count] - 1;
}

- (void)incrementLinePositionsFromIndex:(NSUInteger)index amount:(NSUInteger)amount
{
    for (; index < [self.lines count]; index++) {
        Line* line = self.lines[index];
        
        line.position += amount;
    }
}

- (void)decrementLinePositionsFromIndex:(NSUInteger)index amount:(NSUInteger)amount
{
    for (; index < [self.lines count]; index++) {
        Line* line = self.lines[index];
        
        line.position -= amount;
    }
}

- (void)correctParsesInLines:(NSMutableIndexSet*)lineIndices
{
    while ([lineIndices count] > 0) {
        [self correctParseInLine:[lineIndices lowestIndex] indicesToDo:lineIndices];
    }
}

- (void)correctParseInLine:(NSUInteger)index indicesToDo:(NSMutableIndexSet*)indices
{
    //Remove index as done from array if in array
    if ([indices count]) {
        NSUInteger lowestToDo = [indices lowestIndex];
        if (lowestToDo == index) {
            [indices removeIndex:index];
        }
    }
    
    //Correct type on this line
    Line* currentLine = self.lines[index];
    [self parseTypeAndFormattingForLine:currentLine atIndex:index];
    [self.changedIndices addObject:@(index)];
    
    //If there is a next element, check if it might need a reparse
    if (index < [self.lines count] - 1) {
        Line* nextLine = self.lines[index+1];
        if (currentLine.type == character ||
            currentLine.type == parenthetical ||
            currentLine.type == dialogue ||
            currentLine.type == doubleDialogueCharacter ||
            currentLine.type == doubleDialogueParenthetical ||
            currentLine.type == doubleDialogue ||
            nextLine.type == parenthetical ||
            nextLine.type == dialogue ||
            nextLine.type == doubleDialogueParenthetical ||
            nextLine.type == doubleDialogue) {
            
            [self correctParseInLine:index+1 indicesToDo:indices];
        }
    }
}

#pragma mark Parsing Core

#define BOLD_PATTERN @"**"
#define ITALIC_PATTERN @"*"
#define UNDERLINE_PATTERN @"_"
#define NOTE_OPEN_PATTERN @"[["
#define NOTE_CLOSE_PATTERN @"]]"
#define OMMIT_OPEN_PATTERN @"/*"
#define OMMIT_CLOSE_PATTERN @"*/"

- (void)parseTypeAndFormattingForLine:(Line*)line atIndex:(NSUInteger)index
{
    line.type = [self parseLineType:line.string atIndex:index];
    line.boldRanges = [self rangesInString:line.string between:BOLD_PATTERN and:BOLD_PATTERN];
    line.italicRanges = [self rangesInString:line.string between:ITALIC_PATTERN and:ITALIC_PATTERN];
    line.underlinedRanges = [self rangesInString:line.string between:UNDERLINE_PATTERN and:UNDERLINE_PATTERN];
    line.noteRanges = [self rangesInString:line.string between:NOTE_OPEN_PATTERN and:NOTE_CLOSE_PATTERN];
    line.ommitedRanges = [self rangesInString:line.string between:OMMIT_OPEN_PATTERN and:OMMIT_CLOSE_PATTERN];
}

- (LineType)parseLineType:(NSString*)string atIndex:(NSUInteger)index
{
    NSUInteger length = [string length];
    
    //Check if empty
    if (length == 0) {
        return empty;
    }
    
    char firstChar = [string characterAtIndex:0];
    char lastChar = [string characterAtIndex:length-1];
    
    bool containsOnlyWhitespace = [string containsOnlyWhitespace]; //Save to use again later
    bool twoSpaces = (length == 2 && firstChar == ' ' && lastChar == ' ');
    //If not empty, check if contains only whitespace. Exception: two spaces indicate a continued whatever, so keep them
    if (containsOnlyWhitespace && !twoSpaces) {
        return empty;
    }
    
    //Check for forces (the first character can force a line type)
    if (firstChar == '!') {
        return action;
    }
    if (firstChar == '@') {
        return character;
    }
    if (firstChar == '.') {
        return heading;
    }
    if (firstChar == '~') {
        return lyrics;
    }
    if (firstChar == '>' && lastChar != '<') {
        return transition;
    }
    if (firstChar == '#') {
        return section;
    }
    
    //Check for transitions and page breaks
    if (length >= 3) {
        //Transition happens if the last three chars are "TO:"
        NSRange lastThreeRange = NSMakeRange(length-3, 3);
        NSString *lastThreeChars = [[string substringWithRange:lastThreeRange] lowercaseString];
        if ([lastThreeChars isEqualToString:@"to:"]) {
            return transition;
        }
        
        //Page breaks start with "==="
        NSString *firstChars;
        if (length == 3) {
            firstChars = lastThreeChars;
        } else {
            firstChars = [string substringToIndex:3];
        }
        if ([firstChars isEqualToString:@"==="]) {
            return pageBreak;
        }
    }
    
    //Check for scene headings (lines beginning with "INT", "EXT", "EST",  "I/E"). "INT./EXT" and "INT/EXT" are also inside the spec, but already covered by "INT".
    
    if (length >= 3) {
        NSString* firstChars = [string substringToIndex:3];
        if ([firstChars isEqualToString:@"INT"] ||
            [firstChars isEqualToString:@"EXT"] ||
            [firstChars isEqualToString:@"EST"] ||
            [firstChars isEqualToString:@"I/E"]) {
            return heading;
        }
    }
    
    
    //Check for centered text
    if (firstChar == '>' && lastChar == '<') {
        return centered;
    }
    
    //Check if all uppercase (and at least 3 characters to not indent every capital leter before anything else follows) = character name.
    if (length >= 3 && [string containsOnlyUppercase] && !containsOnlyWhitespace) {
        // A character line ending in ^ is a double dialogue character
        if (lastChar == '^') {
            return doubleDialogueCharacter;
        } else {
            return character;
        }
    }
    
    //Check for title page elements. A title page element starts with "Title:", "Credit:", "Author:", "Draft date:" or "Contact:"
    //it has to be either the first line or only be preceeded by title page elements.
    Line* preceedingLine = (index == 0) ? nil : (Line*) self.lines[index-1];
    if (!preceedingLine ||
        preceedingLine.type == titlePageTitle ||
        preceedingLine.type == titlePageAuthor ||
        preceedingLine.type == titlePageCredit ||
        preceedingLine.type == titlePageSource ||
        preceedingLine.type == titlePageContact ||
        preceedingLine.type == titlePageDraftDate) {
        
        if (length >= 6) {
            NSString *firstChars = [[string substringToIndex:6] lowercaseString];
            if ([firstChars isEqualToString:@"title:"]) {
                return titlePageTitle;
            }
            if (length >= 7) {
                NSString *firstChars = [[string substringToIndex:7] lowercaseString];
                if ([firstChars isEqualToString:@"credit:"]) {
                    return titlePageCredit;
                }
                if ([firstChars isEqualToString:@"author:"]) {
                    return titlePageAuthor;
                }
                if ([firstChars isEqualToString:@"source:"]) {
                    return titlePageSource;
                }
                if (length >= 8) {
                    NSString *firstChars = [[string substringToIndex:8] lowercaseString];
                    if ([firstChars isEqualToString:@"contact:"]) {
                        return titlePageContact;
                    }
                    if (length >= 11) {
                        NSString *firstChars = [[string substringToIndex:11] lowercaseString];
                        if ([firstChars isEqualToString:@"draft date:"]) {
                            return titlePageDraftDate;
                        }
                    }
                }
            }
        }
    }

    //If it's just usual text, see if it might be (double) dialogue or a parenthetical.
    if (preceedingLine) {
        if (preceedingLine.type == dialogue) {
            //Regular text after a dialogue line is another line of dialogue
            return dialogue;
        } else if (preceedingLine.type == doubleDialogue) {
            //Regular text after a double dialogue line is another line of double dialogue
            return doubleDialogue;
        } else if (preceedingLine.type == character) {
            //Text in parentheses after character is a parenthetical, else its dialogue
            if (firstChar == '(' && lastChar == ')') {
                return parenthetical;
            } else {
                return dialogue;
            }
        } else if (preceedingLine.type == doubleDialogueCharacter) {
            //Text in parentheses after character is a parenthetical, else its dialogue
            if (firstChar == '(' && lastChar == ')') {
                return doubleDialogueParenthetical;
            } else {
                return doubleDialogue;
            }
        } else if (preceedingLine.type == parenthetical) {
            //Text after a parenthetical is dialogue, as it's indirectly preceeded by a character
            return dialogue;
        } else if (preceedingLine.type == doubleDialogueParenthetical) {
            //Text after a parenthetical is dialogue, as it's indirectly preceeded by a character
            return doubleDialogue;
        }
    }
    
    return action;
}

- (NSMutableIndexSet*)rangesInString:(NSString*)string between:(NSString*)startString and:(NSString*)endString
{
    NSMutableIndexSet* indexSet = [[NSMutableIndexSet alloc] init];
    
    NSUInteger stringLength = [string length];
    NSUInteger startLength = [startString length];
    NSUInteger endLength = [endString length];
    
    NSInteger lastIndexClose = stringLength - startLength; //Last index to look at if we are looking for start
    NSInteger lastIndexOpen = stringLength - endLength; //Last index to look at if we are looking for end
    NSInteger rangeBegin = -1; //Set to -1 when no range is currently inspected, or the the index of a detected beginning
    
    for (int i = 0;;i++) {
        if (rangeBegin == -1) {
            if (i > lastIndexClose) break;
            //Look for start string
            if ([[string substringWithRange:NSMakeRange(i, startLength)] isEqualToString:startString]) {
                rangeBegin = i;
            }
        } else {
            if (i > lastIndexOpen) break;
            //Lookign for end string
            if ([[string substringWithRange:NSMakeRange(i, endLength)] isEqualToString:endString]) {
                //Only add ranges that contian content
                if (i - rangeBegin != startLength) {
                    [indexSet addIndexesInRange:NSMakeRange(rangeBegin, i - rangeBegin + endLength)];
                }
                rangeBegin = -1;
            }
        }
    }
//    
//    //Terminate any open ranges at the end of the line
//    if (rangeBegin != -1) {
//        //Only add ranges that consist of any more than only the deliminators
//        NSRange rangeToAdd = NSMakeRange(rangeBegin, stringLength - rangeBegin);
//        if (!(rangeToAdd.length == startLength+endLength)) {
//            [indexSet addIndexesInRange:rangeToAdd];
//        }
//    }
    
    return indexSet;
}


#pragma mark - Data access

- (NSString*)stringAtLine:(NSUInteger)line
{
    if (line >= [self.lines count]) {
        return @"";
    } else {
        Line* l = self.lines[line];
        return l.string;
    }
}

- (LineType)typeAtLine:(NSUInteger)line
{
    if (line >= [self.lines count]) {
        return NSNotFound;
    } else {
        Line* l = self.lines[line];
        return l.type;
    }
}

- (NSUInteger)positionAtLine:(NSUInteger)line
{
    if (line >= [self.lines count]) {
        return NSNotFound;
    } else {
        Line* l = self.lines[line];
        return l.position;
    }
}

- (NSString *)toString
{
    NSString *result = @"";
    NSUInteger index = 0;
    for (Line *l in self.lines) {
        //For whatever reason, %lu doesn't work with a zero
        if (index == 0) {
            result = [result stringByAppendingString:@"0 "];
        } else {
            result = [result stringByAppendingFormat:@"%lu ", (unsigned long) index];
        }
        result = [[result stringByAppendingString:[l toString]] stringByAppendingString:@"\n"];
        index++;
    }
    //Cut off the last newline
    result = [result substringToIndex:result.length - 1];
    return result;
}

@end
