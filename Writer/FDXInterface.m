//
//  FDXInterface.m
//  Writer
//
//  Created by Hendrik Noeller on 07.04.16.
//  Copyright © 2016 Hendrik Noeller. All rights reserved.
//
//  Greatly copied from: https://github.com/vilcans/screenplain/blob/master/screenplain/export/fdx.py

#import "FDXInterface.h"
#import "Line.h"

@implementation FDXInterface

+ (NSString*)fdxFromLines:(NSArray*)lines
{
    NSMutableString* result = [@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"
                               @"<FinalDraft DocumentType=\"Script\" Template=\"No\" Version=\"1\">\n"
                               @"\n"
                               @"  <Content>\n" mutableCopy];
    
    for (Line *line in lines) {
        [self appendLine:line toString:result];
    }
    
    [result appendString:@"  </Content>\n"
                         @"</FinalDraft>\n" ];
    
    return result;
}

+ (void)appendLine:(Line*)line toString:(NSMutableString*)result //In python: like write_paragraph but also calcualtes caller arguments
{
    NSString* paragraphType = [self typeAsFDXString:line.type];
    if (paragraphType.length == 0) {
        //Ignore if no type is known
        return;
    }
    if (line.type == centered) {
        [result appendFormat:@"    <Paragraph Alignment=\"Center\" Type=\"%@\">\n", paragraphType];
    } else if (line.type == transition) {
        [result appendFormat:@"    <Paragraph Alignment=\"Right\" Type=\"%@\">\n", paragraphType];
    } else {
        [result appendFormat:@"    <Paragraph Type=\"%@\">\n", paragraphType];
    }
    [self appendLineContents:line toString:result];
    [result appendString:@"    </Paragraph>\n"];
}

+ (void)appendLineContents:(Line*)line toString:(NSMutableString*)result //In python: write_text
{
    
    NSUInteger length = line.string.length;
    NSUInteger appendFromIndex = line.numberOfPreceedingFormattingCharacters;
    
    if (length == 0) {
        return;
    }
    bool lastBold = [line.boldRanges containsIndex:0];
    bool lastItalic = [line.italicRanges containsIndex:0];
    bool lastUnderlined = [line.underlinedRanges containsIndex:0];
    
    if (length == 1) {
        [self appendText:line.string  bold:lastBold italic:lastItalic underlined:lastUnderlined toString:result];
    }
    
    for (NSUInteger i = 1+appendFromIndex; i < length; i++) {
        bool bold = [line.boldRanges containsIndex:i];
        bool italic = [line.italicRanges containsIndex:i];
        bool underlined = [line.underlinedRanges containsIndex:i];
        if (bold != lastBold || italic != lastItalic || underlined != lastUnderlined) {
            NSRange apendRange = NSMakeRange(appendFromIndex, i-1-appendFromIndex);
            [self appendText:[line.string substringWithRange:apendRange] bold:bold italic:italic underlined:underlined toString:result];
            
            appendFromIndex = i;
        }
        lastBold = bold;
        lastItalic = italic;
        lastUnderlined = underlined;
    }
    //Apend last range
    NSRange apendRange = NSMakeRange(appendFromIndex, length-appendFromIndex);
    [self appendText:[line.string substringWithRange:apendRange] bold:lastBold italic:lastItalic underlined:lastUnderlined toString:result];
    
}

#define BOLD_STYLE @"Bold"
#define ITALIC_STYLE @"Italic"
#define UNDERLINE_STYLE @"Underline"

+ (void)appendText:(NSString*)string bold:(bool)bold italic:(bool)italic underlined:(bool)underlined toString:(NSMutableString*)result //In python: _write_text_element
{
    NSString* styleString = @"";
    if (bold) {
        styleString = [styleString stringByAppendingString:BOLD_STYLE];
    }
    if (italic) {
        if (!bold) {
            styleString = [styleString stringByAppendingString:ITALIC_STYLE];
        } else {
            styleString = [styleString stringByAppendingString:UNDERLINE_STYLE];
        }
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
            return @"Action";
        case lyrics:
            return @"Action";
        case pageBreak:
            return @"";
        case centered:
            return @"Action";
    }
}

@end
