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

@interface ContinousFountainParser ()

@property (nonatomic) NSMutableArray *lines; //Stores every line as an element. Multiple lines of stuff
@property (nonatomic) NSMutableArray *changedIndices; //Stores every line that needs to be formatted according to the type
@end

@implementation ContinousFountainParser

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

- (void)parseChange:(NSNotification*)change
{
    
}

- (void)applyFormatChangesInTextView:(NSTextView*)textView
{
    
}

- (void)parseText:(NSString*)text
{
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    for (NSString *rawLine in lines) {
        NSInteger index = [self.lines count];
        LineType type = [self parseLine:rawLine atIndex:index];
        Line* line = [[Line alloc] initWithString:rawLine type:type];
        
        //Add to lines array
        [self.lines addObject:line];
        //Mark change in buffered changes
        [self.changedIndices addObject:@(index)];
    }
}

- (LineType)parseLine:(NSString*)string atIndex:(NSUInteger)index
{
    NSUInteger length = [string length];
    
    //Check if empty
    if (length == 0 ) {
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
    
    //Check for scene headings (lines beginning with "INT", "EXT", "EST", "INT./EXT", "INT/EXT", "I/E"
    if (length >= 8) {
        NSString* firstChars = [string substringToIndex:8];
        if ([firstChars isEqualToString:@"INT./EXT"]) {
            return heading;
        }
        if (length >= 7) {
            firstChars = [string substringToIndex:7];
            if ([firstChars isEqualToString:@"INT/EXT"]) {
                return heading;
            }
            if (length >= 3) {
                firstChars = [string substringToIndex:3];
                if ([firstChars isEqualToString:@"INT"] ||
                    [firstChars isEqualToString:@"EXT"] ||
                    [firstChars isEqualToString:@"EST"] ||
                    [firstChars isEqualToString:@"I/E"]) {
                    return heading;
                }
            }
        }
    }
    
    
    //Check for centered text
    if (firstChar == '>' && lastChar == '<') {
        return centered;
    }
    
    //Check if all uppercase = character name.
    if ([[string uppercaseString] isEqualToString:string] && !containsOnlyWhitespace) {
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

    //If it's just usual text, see if it might be (double) dialogue or a parenthetical
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

- (LineType)typeAtLine:(NSUInteger)line
{
    if (line >= [self.lines count]) {
        return 0;
    } else {
        Line* l = self.lines[line];
        return l.type;
    }
}

- (NSString *)toString
{
    NSString *result = @"";
    NSUInteger index = 0;
    for (Line *l in self.lines) {
        result = [[[result stringByAppendingFormat:@"%lu ", (unsigned long) index] stringByAppendingString:[l toString]] stringByAppendingString:@"\n"];
        index++;
    }
    return result;
}

@end
