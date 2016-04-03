//
//  Line.m
//  Writer
//
//  Created by Hendrik Noeller on 01.04.16.
//  Copyright © 2016 Hendrik Noeller. All rights reserved.
//

#import "Line.h"

@implementation Line

- (Line*)initWithString:(NSString*)string type:(LineType)type
{
    self = [super init];
    if (self) {
        _string = string;
        _type = type;
    }
    return self;
}

- (NSString *)toString
{
    switch (self.type) {
        case empty:
            return [[@"Empty: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case section:
            return [[@"Section: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case titlePageTitle:
            return [[@"Title Page Title: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case titlePageAuthor:
            return [[@"Title Page Author: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case titlePageCredit:
            return [[@"Title Page Credit: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case titlePageSource:
            return [[@"Title Page Source: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case titlePageContact:
            return [[@"Title Page Contact: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case titlePageDraftDate:
            return [[@"Title Page Draft Date: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case heading:
            return [[@"Heading: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case action:
            return [[@"Action: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case character:
            return [[@"Character: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case parenthetical:
            return [[@"Parenthetical: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case dialogue:
            return [[@"Dialogue: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case doubleDialogueCharacter:
            return [[@"DD Character: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case doubleDialogueParenthetical:
            return [[@"DD Parenthetical: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case doubleDialogue:
            return [[@"Double Dialogue: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case transition:
            return [[@"Transition: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case lyrics:
            return [[@"Lyrics: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case pageBreak:
            return [[@"Page Break: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
        case centered:
            return [[@"Centered: \"" stringByAppendingString:self.string] stringByAppendingString:@"\""];
    }
}

@end
