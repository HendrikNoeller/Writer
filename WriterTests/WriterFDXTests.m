//
//  WriterFDXTests.m
//  Writer
//
//  Created by Hendrik Noeller on 07.04.16.
//  Copyright © 2016 Hendrik Noeller. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ContinousFountainParser.h"
#import "FDXInterface.h"

@interface WriterFDXTests : XCTestCase

@end

@implementation WriterFDXTests

- (void)testFDXExport
{
    NSString* fdxString = [FDXInterface fdxFromString:fdxScript];
    NSArray* lines = [fdxString componentsSeparatedByString:@"\n"];
    
    int i = 0;
    XCTAssertEqualObjects(lines[i], @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>"); i++;
    XCTAssertEqualObjects(lines[i], @"<FinalDraft DocumentType=\"Script\" Template=\"No\" Version=\"1\">"); i++;
    XCTAssertEqualObjects(lines[i], @""); i++;
    XCTAssertEqualObjects(lines[i], @"  <Content>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Scene Heading\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>INT. DAY - APPARTMENT</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Action\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>Ted, Marshall and Lilly are sitting on the couch</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Character\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>TED</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Parenthetical\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>(parenthetical)</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Dialogue\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>Wanna head down to the bar?</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Character\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>MARSHALL ^</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Dialogue\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>Sure, let&#x27;s go!</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Alignment=\"Right\" Type=\"Action\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>FADE TO:</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Scene Heading\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>INT. DAY - THE BAR</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Action\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>The jukebox is playing</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Action\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>1 o&#x27;clock, 2 o&#x27;clock, 3&#x27;o clock rock!</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"  </Content>"); i++;
    XCTAssertEqualObjects(lines[i], @"</FinalDraft>"); i++;
    
    
}

- (void)testFormattingExport
{
    NSString* fdxString = [FDXInterface fdxFromString:@"**bold**\n**bold** normal *italic* _underline_ _**boldline**_ _*underitalic*_ ***boldit***\na\n*i*\n*"];
    NSArray* lines = [fdxString componentsSeparatedByString:@"\n"];
    
    int i = 0;
    XCTAssertEqualObjects(lines[i], @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>"); i++;
    XCTAssertEqualObjects(lines[i], @"<FinalDraft DocumentType=\"Script\" Template=\"No\" Version=\"1\">"); i++;
    XCTAssertEqualObjects(lines[i], @""); i++;
    XCTAssertEqualObjects(lines[i], @"  <Content>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Action\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text Style=\"Bold\">bold</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Action\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text Style=\"Bold\">bold</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text> normal </Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text Style=\"Italic\">italic</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text> </Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text Style=\"Underline\">underline</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text> </Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text Style=\"Bold+Underline\">boldline</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text> </Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text Style=\"Italic+Underline\">underitalic</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text> </Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text Style=\"Bold+Italic\">boldit</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Action\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>a</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Action\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text Style=\"Italic\">i</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"    <Paragraph Type=\"Action\">"); i++;
    XCTAssertEqualObjects(lines[i], @"      <Text>*</Text>"); i++;
    XCTAssertEqualObjects(lines[i], @"    </Paragraph>"); i++;
    
    XCTAssertEqualObjects(lines[i], @"  </Content>"); i++;
    XCTAssertEqualObjects(lines[i], @"</FinalDraft>"); i++;
}

- (void)testCharacterEscape
{
    NSString* testString;
    NSMutableString* mutableTestString;
    
    testString = @"this is a usual string äöü? $%è !";
    mutableTestString = [testString mutableCopy];
    [FDXInterface escapeString:mutableTestString];
    
    XCTAssertEqualObjects(mutableTestString, [testString mutableCopy]);
    
    testString = @"&";
    mutableTestString = [testString mutableCopy];
    [FDXInterface escapeString:mutableTestString];
    
    XCTAssertEqualObjects(mutableTestString, [@"&amp;" mutableCopy]);
    
    testString = @"\"";
    mutableTestString = [testString mutableCopy];
    [FDXInterface escapeString:mutableTestString];
    
    XCTAssertEqualObjects(mutableTestString, [@"&quot;" mutableCopy]);
    
    testString = @"'";
    mutableTestString = [testString mutableCopy];
    [FDXInterface escapeString:mutableTestString];
    
    XCTAssertEqualObjects(mutableTestString, [@"&#x27;" mutableCopy]);
    
    testString = @"<";
    mutableTestString = [testString mutableCopy];
    [FDXInterface escapeString:mutableTestString];
    
    XCTAssertEqualObjects(mutableTestString, [@"&lt;" mutableCopy]);
    
    testString = @">";
    mutableTestString = [testString mutableCopy];
    [FDXInterface escapeString:mutableTestString];
    
    XCTAssertEqualObjects(mutableTestString, [@"&gt;" mutableCopy]);
    
    testString = @"&\"'<>";
    mutableTestString = [testString mutableCopy];
    [FDXInterface escapeString:mutableTestString];
    
    XCTAssertEqualObjects(mutableTestString, [@"&amp;&quot;&#x27;&lt;&gt;" mutableCopy]);
}

NSString* fdxScript = @"INT. DAY - APPARTMENT\n"
@"\n"
@"Ted, Marshall and Lilly are sitting on the couch\n"
@"\n"
@"TED\n"
@"(parenthetical)\n"
@"Wanna head down to the bar?\n"
@"\n"
@"MARSHALL ^\n"
@"Sure, let's go!\n"
@"FADE TO:\n"
@"\n"
@"INT. DAY - THE BAR\n"
@"The jukebox is playing\n"
@"~1 o'clock, 2 o'clock, 3'o clock rock!\n";


@end
