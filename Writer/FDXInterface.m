//
//  FDXInterface.m
//  Writer
//
//  Created by Hendrik Noeller on 07.04.16.
//  Copyright © 2016 Hendrik Noeller. All rights reserved.
//
//  Greatly copied from: https://github.com/vilcans/screenplain/blob/master/screenplain/export/fdx.py

#import "FDXInterface.h"
#import "ContinousFountainParser.h"
#import "Line.h"

@implementation FDXInterface

+ (NSString*)fdxFromString:(NSString*)string
{
    
    
    ContinousFountainParser* parser = [[ContinousFountainParser alloc] initWithString:string];
    NSMutableString* result = [@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"
                               @"<FinalDraft DocumentType=\"Script\" Template=\"No\" Version=\"1\">\n"
                               @"\n"
                               @"  <Content>\n" mutableCopy];
    
    bool inDoubleDialogue = false;
    for (int i = 0; i < [parser.lines count]; i++) {
        inDoubleDialogue = [self appendLineAtIndex:i fromLines:parser.lines toString:result inDoubleDialogue:inDoubleDialogue];
    }
    
    [result appendString:@"  </Content>\n"
                         @"</FinalDraft>\n" ];
    
    return result;
}

+ (bool)appendLineAtIndex:(NSUInteger)index fromLines:(NSArray*)lines toString:(NSMutableString*)result inDoubleDialogue:(bool)inDoubleDialogue//In python: like write_paragraph but also calcualtes caller arguments
{
    Line* line = lines[index];
    NSString* paragraphType = [self typeAsFDXString:line.type];
    if (paragraphType.length == 0) {
        //Ignore if no type is known
        return inDoubleDialogue;
    }
    
    
    
    //If no double dialogue is currently in action, and a dialogue should be printed, check if it is followed by double dialogue so both can be wrapped in a double dialogue
    if (!inDoubleDialogue && line.type == character) {
        for (NSUInteger i = index + 1; i < [lines count]; i++) {
            Line* futureLine = lines[i];
            if (futureLine.type == parenthetical ||
                futureLine.type == dialogue ||
                futureLine.type == empty) {
                continue;
            }
            if (futureLine.type == doubleDialogueCharacter) {
                inDoubleDialogue = true;
            }
            break;
        }
        if (inDoubleDialogue) {
            [result appendString:@"    <Paragraph>\n"];
            [result appendString:@"      <DualDialogue>\n"];
        }
    }
    
    
    
    //Append Open Paragraph Tag
    if (line.type == centered) {
        [result appendFormat:@"    <Paragraph Alignment=\"Center\" Type=\"%@\">\n", paragraphType];
    } else {
        [result appendFormat:@"    <Paragraph Type=\"%@\">\n", paragraphType];
    }
    
    //Append content
    [self appendLineContents:line toString:result];
    
    //Apend close paragraph
    [result appendString:@"    </Paragraph>\n"];
    
    
    
    //If a double dialogue is currently in action, check wether it needs to be closed after this
    if (inDoubleDialogue) {
        if (index < [lines count] - 1) {
            //If the line is double dialogue, and the next one isn't, it's time to close the dual dialogue tag
            if (line.type == doubleDialogue) {
                Line* nextLine = lines[index+1];
                if (nextLine.type != doubleDialogue) {
                    inDoubleDialogue = false;
                    [result appendString:@"      </DualDialogue>\n"];
                    [result appendString:@"    </Paragraph>\n"];
                }
            }
        } else {
            //If the line is the last line, it's also time to close the dual dialogue tag
            inDoubleDialogue = false;
            [result appendString:@"      </DualDialogue>\n"];
            [result appendString:@"    </Paragraph>\n"];
        }
    }
    
    return inDoubleDialogue;
}

#define BOLD_PATTERN_LENGTH 2
#define ITALIC_UNDERLINE_PATTERN_LENGTH 1

+ (void)appendLineContents:(Line*)line toString:(NSMutableString*)result //In python: write_text
{
    //Remove all formatting symbols from the line and the ranges
    NSMutableString* string = [line.string mutableCopy];
    
    NSMutableIndexSet* boldRanges = [line.boldRanges mutableCopy];
    NSMutableIndexSet* italicRanges = [line.italicRanges mutableCopy];
    NSMutableIndexSet* underlinedRanges = [line.underlinedRanges mutableCopy];
    int __block removedChars = 0;
    
    NSMutableIndexSet* currentRanges = [boldRanges mutableCopy];
    
    [currentRanges enumerateRangesWithOptions:0 usingBlock:^(NSRange range, BOOL * _Nonnull stop) {
        NSRange beginSymbolRange = NSMakeRange(range.location - removedChars, BOLD_PATTERN_LENGTH);
        NSRange endSymbolRange = NSMakeRange(range.location + range.length - 2*BOLD_PATTERN_LENGTH - removedChars, BOLD_PATTERN_LENGTH); //after deleting begin symboL!
        
        [string replaceCharactersInRange:beginSymbolRange withString:@""];
        [string replaceCharactersInRange:endSymbolRange withString:@""];
        
        [boldRanges shiftIndexesStartingAtIndex:beginSymbolRange.location+beginSymbolRange.length
                                             by:-beginSymbolRange.length];
        [boldRanges shiftIndexesStartingAtIndex:endSymbolRange.location+endSymbolRange.length
                                             by:-endSymbolRange.length];
        [italicRanges shiftIndexesStartingAtIndex:beginSymbolRange.location+beginSymbolRange.length
                                               by:-beginSymbolRange.length];
        [italicRanges shiftIndexesStartingAtIndex:endSymbolRange.location+endSymbolRange.length
                                               by:-endSymbolRange.length];
        [underlinedRanges shiftIndexesStartingAtIndex:beginSymbolRange.location+beginSymbolRange.length
                                                   by:-beginSymbolRange.length];
        [underlinedRanges shiftIndexesStartingAtIndex:endSymbolRange.location+endSymbolRange.length
                                                   by:-endSymbolRange.length];
        
        removedChars += BOLD_PATTERN_LENGTH*2;
    }];
    removedChars = 0;
    
    currentRanges = [italicRanges mutableCopy];
    
    [currentRanges enumerateRangesWithOptions:0 usingBlock:^(NSRange range, BOOL * _Nonnull stop) {
        NSRange beginSymbolRange = NSMakeRange(range.location - removedChars, ITALIC_UNDERLINE_PATTERN_LENGTH);
        NSRange endSymbolRange = NSMakeRange(range.location + range.length - 2*ITALIC_UNDERLINE_PATTERN_LENGTH - removedChars, ITALIC_UNDERLINE_PATTERN_LENGTH);
        
        [string replaceCharactersInRange:beginSymbolRange withString:@""];
        [string replaceCharactersInRange:endSymbolRange withString:@""];
        
        [boldRanges shiftIndexesStartingAtIndex:beginSymbolRange.location+beginSymbolRange.length
                                             by:-beginSymbolRange.length];
        [boldRanges shiftIndexesStartingAtIndex:endSymbolRange.location+endSymbolRange.length
                                             by:-endSymbolRange.length];
        [italicRanges shiftIndexesStartingAtIndex:beginSymbolRange.location+beginSymbolRange.length
                                               by:-beginSymbolRange.length];
        [italicRanges shiftIndexesStartingAtIndex:endSymbolRange.location+endSymbolRange.length
                                               by:-endSymbolRange.length];
        [underlinedRanges shiftIndexesStartingAtIndex:beginSymbolRange.location+beginSymbolRange.length
                                                   by:-beginSymbolRange.length];
        [underlinedRanges shiftIndexesStartingAtIndex:endSymbolRange.location+endSymbolRange.length
                                                   by:-endSymbolRange.length];
        
        removedChars += ITALIC_UNDERLINE_PATTERN_LENGTH*2;
    }];
    removedChars = 0;
    
    currentRanges = [underlinedRanges mutableCopy];
    
    [currentRanges enumerateRangesWithOptions:0 usingBlock:^(NSRange range, BOOL * _Nonnull stop) {
        NSRange beginSymbolRange = NSMakeRange(range.location - removedChars, ITALIC_UNDERLINE_PATTERN_LENGTH);
        NSRange endSymbolRange = NSMakeRange(range.location + range.length - 2*ITALIC_UNDERLINE_PATTERN_LENGTH - removedChars, ITALIC_UNDERLINE_PATTERN_LENGTH);
        
        [string replaceCharactersInRange:beginSymbolRange withString:@""];
        [string replaceCharactersInRange:endSymbolRange withString:@""];
        
        [boldRanges shiftIndexesStartingAtIndex:beginSymbolRange.location+beginSymbolRange.length
                                             by:-beginSymbolRange.length];
        [boldRanges shiftIndexesStartingAtIndex:endSymbolRange.location+endSymbolRange.length
                                             by:-endSymbolRange.length];
        [italicRanges shiftIndexesStartingAtIndex:beginSymbolRange.location+beginSymbolRange.length
                                               by:-beginSymbolRange.length];
        [italicRanges shiftIndexesStartingAtIndex:endSymbolRange.location+endSymbolRange.length
                                               by:-endSymbolRange.length];
        [underlinedRanges shiftIndexesStartingAtIndex:beginSymbolRange.location+beginSymbolRange.length
                                                   by:-beginSymbolRange.length];
        [underlinedRanges shiftIndexesStartingAtIndex:endSymbolRange.location+endSymbolRange.length
                                                   by:-endSymbolRange.length];
        
        removedChars += ITALIC_UNDERLINE_PATTERN_LENGTH*2;

    }];
    
    //Remove the > < from centered text
    if (line.type == centered) {
        [string replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        [string replaceCharactersInRange:NSMakeRange(string.length - 1, 1) withString:@""];
        [boldRanges shiftIndexesStartingAtIndex:1 by:-1];
        [italicRanges shiftIndexesStartingAtIndex:1 by:-1];
        [underlinedRanges shiftIndexesStartingAtIndex:1 by:-1];
    }
    
    //Remove the " ^" from double dialogue character
    if (line.type == doubleDialogueCharacter) {
        [string replaceCharactersInRange:NSMakeRange(string.length - 1, 1) withString:@""];
        while ([string characterAtIndex:string.length - 1] == ' ') {
            [string replaceCharactersInRange:NSMakeRange(string.length - 1, 1) withString:@""];
        }
    }
    
    NSUInteger length = string.length;
    NSUInteger appendFromIndex = line.numberOfPreceedingFormattingCharacters;
    
    bool lastBold = [boldRanges containsIndex:appendFromIndex];
    bool lastItalic = [italicRanges containsIndex:appendFromIndex];
    bool lastUnderlined = [underlinedRanges containsIndex:appendFromIndex];
    
    if (length == 0) {
        return;
    } else if (length == 1) {
        [self appendText:string  bold:lastBold italic:lastItalic underlined:lastUnderlined toString:result];
        return;
    }
    
    for (NSUInteger i = 1+appendFromIndex; i < length; i++) {
        bool bold = [boldRanges containsIndex:i];
        bool italic = [italicRanges containsIndex:i];
        bool underlined = [underlinedRanges containsIndex:i];
        if (bold != lastBold || italic != lastItalic || underlined != lastUnderlined) {
            NSRange appendRange = NSMakeRange(appendFromIndex, i-appendFromIndex);
            
            if (length > 0 && appendRange.location + appendRange.length <= length) {
                [self appendText:[string substringWithRange:appendRange] bold:lastBold italic:lastItalic underlined:lastUnderlined toString:result];
            }
            
            appendFromIndex = i;
            lastBold = bold;
            lastItalic = italic;
            lastUnderlined = underlined;
        }
    }
    //append last range
    NSRange appendRange = NSMakeRange(appendFromIndex, length-appendFromIndex);
    [self appendText:[string substringWithRange:appendRange] bold:lastBold italic:lastItalic underlined:lastUnderlined toString:result];
    
}

#define BOLD_STYLE @"Bold"
#define ITALIC_STYLE @"Italic"
#define UNDERLINE_STYLE @"Underline"

+ (void)appendText:(NSString*)string bold:(bool)bold italic:(bool)italic underlined:(bool)underlined toString:(NSMutableString*)result //In python: _write_text_element
{
    NSMutableString* styleString = [[NSMutableString alloc] init];
    if (bold) {
        [styleString appendString:BOLD_STYLE];
    }
    if (italic) {
        if (bold) {
            [styleString appendString:@"+"];
        }
        [styleString appendString:ITALIC_STYLE];
    }
    if (underlined) {
        if (bold || italic) {
            [styleString appendString:@"+"];
        }
        [styleString appendString:UNDERLINE_STYLE];
    }

    NSMutableString* escapedString = [string mutableCopy];
    [self escapeString:escapedString];
    
    if (!bold && !italic && !underlined) {
        [result appendFormat:@"      <Text>%@</Text>\n", escapedString];
    } else {
        [result appendFormat:@"      <Text Style=\"%@\">%@</Text>\n", styleString, escapedString];
    }
}

+ (void)escapeString:(NSMutableString*)string
{
    [string replaceOccurrencesOfString:@"&"  withString:@"&amp;"  options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"'"  withString:@"&#x27;" options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@">"  withString:@"&gt;"   options:NSLiteralSearch range:NSMakeRange(0, [string length])];
    [string replaceOccurrencesOfString:@"<"  withString:@"&lt;"   options:NSLiteralSearch range:NSMakeRange(0, [string length])];
}

+ (NSString*)typeAsFDXString:(LineType)type
{
    switch (type) {
        case empty:
            return @"";
        case section:
            return @"";
        case synopse:
            return @"";
        case titlePageTitle:
            return @"";
        case titlePageAuthor:
            return @"";
        case titlePageCredit:
            return @"";
        case titlePageSource:
            return @"";
        case titlePageContact:
            return @"";
        case titlePageDraftDate:
            return @"";
        case titlePageUnknown:
            return @"";
        case heading:
            return @"Scene Heading";
        case action:
            return @"Action";
        case character:
            return @"Character";
        case parenthetical:
            return @"Parenthetical";
        case dialogue:
            return @"Dialogue";
        case doubleDialogueCharacter:
            return @"Character";
        case doubleDialogueParenthetical:
            return @"Parenthetical";
        case doubleDialogue:
            return @"Dialogue";
        case transition:
            return @"Transition";
        case lyrics:
            return @"Lyrics";
        case pageBreak:
            return @"";
        case centered:
            return @"Action";
    }
}

@end
