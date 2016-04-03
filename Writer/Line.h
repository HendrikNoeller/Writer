//
//  Line.h
//  Writer
//
//  Created by Hendrik Noeller on 01.04.16.
//  Copyright © 2016 Hendrik Noeller. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    empty = 0,
    section,
    titlePageTitle,
    titlePageAuthor,
    titlePageCredit,
    titlePageSource,
    titlePageContact,
    titlePageDraftDate,
    heading,
    action,
    character,
    parenthetical,
    dialogue,
    doubleDialogueCharacter,
    doubleDialogueParenthetical,
    doubleDialogue,
    transition,
    lyrics,
    pageBreak,
    centered,
} LineType;


@interface Line : NSObject

@property LineType type;
@property (strong, nonatomic) NSString* string;
@property NSUInteger position;

- (Line*)initWithString:(NSString*)string type:(LineType)type position:(NSUInteger)position;
- (NSString*)toString;

@end
