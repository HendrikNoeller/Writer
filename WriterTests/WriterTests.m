//
//  WriterTests.m
//  WriterTests
//
//  Created by Hendrik Noeller on 05.10.14.
//  Copyright (c) 2016 Hendrik Noeller. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "ContinousFountainParser.h"

@interface WriterTests : XCTestCase

@end

@implementation WriterTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitialParse {
    //An example script
    
    ContinousFountainParser *parser = [[ContinousFountainParser alloc] initWithString:script];
    
    NSUInteger i = 0; //User a counter and add "i++" after each line to prevent changing all numbers on every insertion
    XCTAssertEqual([parser typeAtLine:i], titlePageTitle);
    XCTAssertEqual([parser positionAtLine:i], 0); i++;
    XCTAssertEqual([parser typeAtLine:i], titlePageAuthor);
    XCTAssertEqual([parser positionAtLine:i], 14); i++;
    XCTAssertEqual([parser typeAtLine:i], titlePageCredit);
    XCTAssertEqual([parser positionAtLine:i], 36); i++;
    XCTAssertEqual([parser typeAtLine:i], titlePageSource); i++;
    XCTAssertEqual([parser typeAtLine:i], titlePageDraftDate); i++;
    XCTAssertEqual([parser typeAtLine:i], titlePageContact); i++;
    XCTAssertEqual([parser typeAtLine:i], empty); i++;
    XCTAssertEqual([parser typeAtLine:i], heading); i++;
    XCTAssertEqual([parser typeAtLine:i], heading); i++;
    XCTAssertEqual([parser typeAtLine:i], action); i++;
    XCTAssertEqual([parser typeAtLine:i], empty); i++;
    XCTAssertEqual([parser typeAtLine:i], character); i++;
    XCTAssertEqual([parser typeAtLine:i], dialogue); i++;
    XCTAssertEqual([parser typeAtLine:i], dialogue); i++;
    XCTAssertEqual([parser typeAtLine:i], empty); i++;
    XCTAssertEqual([parser typeAtLine:i], doubleDialogueCharacter); i++;
    XCTAssertEqual([parser typeAtLine:i], doubleDialogue); i++;
    XCTAssertEqual([parser typeAtLine:i], empty); i++;
    XCTAssertEqual([parser typeAtLine:i], character); i++;
    XCTAssertEqual([parser typeAtLine:i], parenthetical); i++;
    XCTAssertEqual([parser typeAtLine:i], dialogue); i++;
    XCTAssertEqual([parser typeAtLine:i], dialogue); i++;
    XCTAssertEqual([parser typeAtLine:i], empty); i++;
    XCTAssertEqual([parser typeAtLine:i], doubleDialogueCharacter); i++;
    XCTAssertEqual([parser typeAtLine:i], doubleDialogueParenthetical); i++;
    XCTAssertEqual([parser typeAtLine:i], doubleDialogue); i++;
    XCTAssertEqual([parser typeAtLine:i], doubleDialogue); i++;
    XCTAssertEqual([parser typeAtLine:i], doubleDialogue); i++;
    XCTAssertEqual([parser typeAtLine:i], empty); i++;
    XCTAssertEqual([parser typeAtLine:i], action); i++;
    XCTAssertEqual([parser typeAtLine:i], transition); i++;
    XCTAssertEqual([parser typeAtLine:i], heading); i++;
    XCTAssertEqual([parser typeAtLine:i], action); i++;
    XCTAssertEqual([parser typeAtLine:i], lyrics); i++;
    XCTAssertEqual([parser typeAtLine:i], transition); i++;
    XCTAssertEqual([parser typeAtLine:i], empty); i++;
    XCTAssertEqual([parser typeAtLine:i], action); i++;
    XCTAssertEqual([parser typeAtLine:i], centered); i++;
    XCTAssertEqual([parser typeAtLine:i], pageBreak); i++;
    XCTAssertEqual([parser typeAtLine:i], pageBreak); i++;
    XCTAssertEqual([parser typeAtLine:i], action); i++;
}


NSString *script = @""
@"Title: Script\n"
@"Author: Florian Maier\n"
@"Credit: Thomas Maier\n"
@"source: somewhere\n"
@"DrAft Date: 42.23.23\n"
@"Contact: florian@maier.de\n"
@"\n"
@"INT. DAY - LIVING ROOM\n"
@"EXT. DAY - LIVING ROOM\n"
@"Peter sits somewhere and does something\n"
@"\n"
@"PETER\n"
@"I Like sitting here\n"
@"it makes me happy\n"
@"\n"
@"CHRIS ^\n"
@"i'm also a person!\n"
@"\n"
@"HARRAY\n"
@"(slightly irritated)\n"
@"Why do i have parentheses?\n"
@"They are weird!\n"
@"\n"
@"CHIRS ^\n"
@"(looking at harray)\n"
@"Why am i over here?\n"
@"  \n"
@"And I have holes in my text!\n"
@"\n"
@"He indeed looks very happy\n"
@"fade to:\n"
@".thisisaheading\n"
@"!THISISACTION\n"
@"~lyrics and stuff in this line\n"
@">transition\n"
@"      \n"
@"title: this is not the title page!\n"
@">center!<\n"
@"===\n"
@"======\n"
@"This is on a new page\n";

@end
