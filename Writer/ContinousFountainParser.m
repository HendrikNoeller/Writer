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
        Line* line = [[Line alloc] initWithString:rawLine position:positon];
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
//        [self parseChangeInRange:range withString:@""];
        //First remove
        for (int i = 0; i < range.length; i++) {
            [changedIndices addIndexes:[self parseCharacterRemovedAtPosition:range.location]];
        }
//        [self parseChangeInRange:NSMakeRange(range.location, 0)
//                      withString:string];
        // Then add
        for (int i = 0; i < string.length; i++) {
            NSString* character = [string substringWithRange:NSMakeRange(i, 1)];
            [changedIndices addIndexes:[self parseCharacterAdded:character
                                                      atPosition:range.location+i]];
        }
    }
    
    [self correctParsesInLines:changedIndices];
}

- (NSIndexSet*)parseCharacterAdded:(NSString*)character atPosition:(NSUInteger)position
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
        
        Line* newLine = [[Line alloc] initWithString:cutOffString
                                            position:position+1];
        newLine.type = [self parseLineType:newLine
                                   atIndex:lineIndex+1];
        [self.lines insertObject:newLine atIndex:lineIndex+1];
        
        [self incrementLinePositionsFromIndex:lineIndex+2 amount:1];
        
        return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lineIndex, 2)];
    } else {
        NSArray* pieces = @[[line.string substringToIndex:indexInLine],
                            character,
                            [line.string substringFromIndex:indexInLine]];
        
        line.string = [pieces componentsJoinedByString:@""];
        [self incrementLinePositionsFromIndex:lineIndex+1 amount:1];
        
        return [[NSIndexSet alloc] initWithIndex:lineIndex];
        
    }
}

- (NSIndexSet*)parseCharacterRemovedAtPosition:(NSUInteger)position
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
        
        return [[NSIndexSet alloc] initWithIndex:lineIndex];
    } else {
        NSArray* pieces = @[[line.string substringToIndex:indexInLine],
                            [line.string substringFromIndex:indexInLine+1]];
        
        line.string = [pieces componentsJoinedByString:@""];
        [self decrementLinePositionsFromIndex:lineIndex+1 amount:1];
        
        
        return [[NSIndexSet alloc] initWithIndex:lineIndex];
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
            nextLine.type == doubleDialogue ||
            nextLine.ommitIn != currentLine.ommitOut) {
            
            [self correctParseInLine:index+1 indicesToDo:indices];
        }
    }
}


#pragma mark Parsing Core

#define BOLD_PATTERN "**"
#define ITALIC_PATTERN "*"
#define UNDERLINE_PATTERN "_"
#define NOTE_OPEN_PATTERN "[["
#define NOTE_CLOSE_PATTERN "]]"
#define OMMIT_OPEN_PATTERN "/*"
#define OMMIT_CLOSE_PATTERN "*/"

#define BOLD_PATTERN_LENGTH 2
#define ITALIC_PATTERN_LENGTH 1
#define UNDERLINE_PATTERN_LENGTH 1
#define NOTE_PATTERN_LENGTH 2
#define OMMIT_PATTERN_LENGTH 2

- (void)parseTypeAndFormattingForLine:(Line*)line atIndex:(NSUInteger)index
{
    line.type = [self parseLineType:line atIndex:index];
    
    NSUInteger length = line.string.length;
    unichar charArray[length];
    [line.string getCharacters:charArray];
    
    NSMutableIndexSet* starsInOmmit = [[NSMutableIndexSet alloc] init];
    if (index == 0) {
        line.ommitedRanges = [self rangesOfOmmitChars:charArray
                                             ofLength:length
                                               inLine:line
                                     lastLineOmmitOut:NO
                                          saveStarsIn:starsInOmmit];
    } else {
        Line* previousLine = self.lines[index-1];
        line.ommitedRanges = [self rangesOfOmmitChars:charArray
                                             ofLength:length
                                               inLine:line
                                     lastLineOmmitOut:previousLine.ommitOut
                                          saveStarsIn:starsInOmmit];
    }
    
    line.boldRanges = [self rangesInChars:charArray
                                 ofLength:length
                                  between:BOLD_PATTERN
                                      and:BOLD_PATTERN
                               withLength:BOLD_PATTERN_LENGTH
                         excludingIndices:starsInOmmit];
    line.italicRanges = [self rangesInChars:charArray
                                   ofLength:length
                                    between:ITALIC_PATTERN
                                        and:ITALIC_PATTERN
                                 withLength:ITALIC_PATTERN_LENGTH
                           excludingIndices:starsInOmmit];
    line.underlinedRanges = [self rangesInChars:charArray
                                       ofLength:length
                                        between:UNDERLINE_PATTERN
                                            and:UNDERLINE_PATTERN
                                     withLength:UNDERLINE_PATTERN_LENGTH
                               excludingIndices:nil];
    line.noteRanges = [self rangesInChars:charArray
                                 ofLength:length
                                  between:NOTE_OPEN_PATTERN
                                      and:NOTE_CLOSE_PATTERN
                               withLength:NOTE_PATTERN_LENGTH
                         excludingIndices:nil];
}

- (LineType)parseLineType:(Line*)line atIndex:(NSUInteger)index
{
    NSString* string = line.string;
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
        line.numberOfPreceedingFormattingCharacters = 1;
        return action;
    }
    if (firstChar == '@') {
        line.numberOfPreceedingFormattingCharacters = 1;
        return character;
    }
    if (firstChar == '~') {
        line.numberOfPreceedingFormattingCharacters = 1;
        return lyrics;
    }
    if (firstChar == '>' && lastChar != '<') {
        line.numberOfPreceedingFormattingCharacters = 1;
        return transition;
    }
    if (firstChar == '#') {
        line.numberOfPreceedingFormattingCharacters = 1;
        return section;
    }
    if (firstChar == '=' && (length >= 2 ? [string characterAtIndex:1] != '=' : YES)) {
        line.numberOfPreceedingFormattingCharacters = 1;
        return synopse;
    }
    if (firstChar == '.' && length >= 2 && [string characterAtIndex:1] != '.') {
        line.numberOfPreceedingFormattingCharacters = 1;
        return heading;
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
        preceedingLine.type == titlePageDraftDate ||
        preceedingLine.type == titlePageUnknown) {
        
        //Check for title page key: value pairs
        // - search for ":"
        // - extract key
        NSRange firstColonRange = [string rangeOfString:@":"];
        if (firstColonRange.length != 0) {
            NSUInteger firstColonIndex = firstColonRange.location;
            
            NSString* key = [[string substringToIndex:firstColonIndex] lowercaseString];
            
            if ([key isEqualToString:@"title"]) {
                return titlePageTitle;
            } else if ([key isEqualToString:@"author"] || [key isEqualToString:@"authors"]) {
                return titlePageAuthor;
            } else if ([key isEqualToString:@"credit"]) {
                return titlePageCredit;
            } else if ([key isEqualToString:@"source"]) {
                return titlePageSource;
            } else if ([key isEqualToString:@"contact"]) {
                return titlePageContact;
            } else if ([key isEqualToString:@"draft date"]) {
                return titlePageDraftDate;
            } else {
                return titlePageUnknown;
            }
        } else {
            if (length >= 2 && [[string substringToIndex:2] isEqualToString:@"  "]) {
                line.numberOfPreceedingFormattingCharacters = 2;
                return preceedingLine.type;
            } else if (length >= 1 && [[string substringToIndex:1] isEqualToString:@"\t"]) {
                line.numberOfPreceedingFormattingCharacters = 1;
                return preceedingLine.type;
            }
        }
        
    }
    
    //Check for scene headings (lines beginning with "INT", "EXT", "EST",  "I/E"). "INT./EXT" and "INT/EXT" are also inside the spec, but already covered by "INT".
    
    if (length >= 3) {
        NSString* firstChars = [[string substringToIndex:3] lowercaseString];
        if ([firstChars isEqualToString:@"int"] ||
            [firstChars isEqualToString:@"ext"] ||
            [firstChars isEqualToString:@"est"] ||
            [firstChars isEqualToString:@"i/e"]) {
            return heading;
        }
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
    
    //Check if all uppercase (and at least 3 characters to not indent every capital leter before anything else follows) = character name.
    if (length >= 3 && [string containsOnlyUppercase] && !containsOnlyWhitespace) {
        // A character line ending in ^ is a double dialogue character
        if (lastChar == '^') {
            return doubleDialogueCharacter;
        } else {
            return character;
        }
    }
    
    //Check for centered text
    if (firstChar == '>' && lastChar == '<') {
        return centered;
    }

    //If it's just usual text, see if it might be (double) dialogue or a parenthetical.
    if (preceedingLine) {
        if (preceedingLine.type == character || preceedingLine.type == dialogue || preceedingLine.type == parenthetical) {
            //Text in parentheses after character or dialogue is a parenthetical, else its dialogue
            if (firstChar == '(' && lastChar == ')') {
                return parenthetical;
            } else {
                return dialogue;
            }
        } else if (preceedingLine.type == doubleDialogueCharacter || preceedingLine.type == doubleDialogue || preceedingLine.type == doubleDialogueParenthetical) {
            //Text in parentheses after character or dialogue is a parenthetical, else its dialogue
            if (firstChar == '(' && lastChar == ')') {
                return doubleDialogueParenthetical;
            } else {
                return doubleDialogue;
            }
        }
    }
    
    return action;
}

- (NSMutableIndexSet*)rangesInChars:(unichar*)string ofLength:(NSUInteger)length between:(char*)startString and:(char*)endString withLength:(NSUInteger)delimLength excludingIndices:(NSIndexSet*)excludes
{
    NSMutableIndexSet* indexSet = [[NSMutableIndexSet alloc] init];
    
    NSInteger lastIndex = length - delimLength; //Last index to look at if we are looking for start
    NSInteger rangeBegin = -1; //Set to -1 when no range is currently inspected, or the the index of a detected beginning
    
    for (int i = 0;;i++) {
        if (i > lastIndex) break;
        if ([excludes containsIndex:i]) continue;
        if (rangeBegin == -1) {
            bool match = YES;
            for (int j = 0; j < delimLength; j++) {
                if (string[j+i] != startString[j]) {
                    match = NO;
                    break;
                }
            }
            if (match) {
                rangeBegin = i;
                i += delimLength - 1;
            }
        } else {
            bool match = YES;
            for (int j = 0; j < delimLength; j++) {
                if (string[j+i] != endString[j]) {
                    match = NO;
                    break;
                }
            }
            if (match) {
                [indexSet addIndexesInRange:NSMakeRange(rangeBegin, i - rangeBegin + delimLength)];
                rangeBegin = -1;
                i += delimLength - 1;
            }
        }
    }
    return indexSet;
}

- (NSMutableIndexSet*)rangesOfOmmitChars:(unichar*)string ofLength:(NSUInteger)length inLine:(Line*)line lastLineOmmitOut:(bool)lastLineOut saveStarsIn:(NSMutableIndexSet*)stars
{
    NSMutableIndexSet* indexSet = [[NSMutableIndexSet alloc] init];
    
    NSInteger lastIndex = length - OMMIT_PATTERN_LENGTH; //Last index to look at if we are looking for start
    NSInteger rangeBegin = lastLineOut ? 0 : -1; //Set to -1 when no range is currently inspected, or the the index of a detected beginning
    line.ommitIn = lastLineOut;
    
    for (int i = 0;;i++) {
        if (i > lastIndex) break;
        if (rangeBegin == -1) {
            bool match = YES;
            for (int j = 0; j < OMMIT_PATTERN_LENGTH; j++) {
                if (string[j+i] != OMMIT_OPEN_PATTERN[j]) {
                    match = NO;
                    break;
                }
            }
            if (match) {
                rangeBegin = i;
                [stars addIndex:i+1];
            }
        } else {
            bool match = YES;
            for (int j = 0; j < OMMIT_PATTERN_LENGTH; j++) {
                if (string[j+i] != OMMIT_CLOSE_PATTERN[j]) {
                    match = NO;
                    break;
                }
            }
            if (match) {
                [indexSet addIndexesInRange:NSMakeRange(rangeBegin, i - rangeBegin + OMMIT_PATTERN_LENGTH)];
                rangeBegin = -1;
                [stars addIndex:i];
            }
        }
    }
    
    //Terminate any open ranges at the end of the line so that this line is ommited untill the end
    if (rangeBegin != -1) {
        NSRange rangeToAdd = NSMakeRange(rangeBegin, length - rangeBegin);
        [indexSet addIndexesInRange:rangeToAdd];
        line.ommitOut = YES;
    } else {
        line.ommitOut = NO;
    }
    
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
