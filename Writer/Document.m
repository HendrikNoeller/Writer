//
//  Document.m
//  Writer
//
//  Created by Hendrik Noeller on 05.10.14.
//  Copyright (c) 2016 Hendrik Noeller. All rights reserved.

//

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <WebKit/WebKit.h>
#import "Document.h"
#import "FNScript.h"
#import "FNHTMLScript.h"
#import "PrintView.h"
#import "ColorView.h"
#import "ContinousFountainParser.h"

@interface Document ()

@property (unsafe_unretained) IBOutlet NSToolbar *toolbar;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (unsafe_unretained) IBOutlet WebView *webView;
@property (unsafe_unretained) IBOutlet NSTabView *tabView;
@property (weak) IBOutlet ColorView *backgroundView;

#pragma mark - Toolbar Buttons
@property (weak) IBOutlet NSButton *boldToolbarButton;
@property (weak) IBOutlet NSButton *italicToolbarButton;
@property (weak) IBOutlet NSButton *underlineToolbarButton;
@property (weak) IBOutlet NSButton *ommitToolbarButton;
@property (weak) IBOutlet NSButton *noteToolbarButton;
@property (weak) IBOutlet NSButton *forceHeadingToolbarButton;
@property (weak) IBOutlet NSButton *forceActionToolbarButton;
@property (weak) IBOutlet NSButton *forceCharacterToolbarButton;
@property (weak) IBOutlet NSButton *forceTransitionToolbarButton;
@property (weak) IBOutlet NSButton *forceLyricsToolbarButton;
@property (weak) IBOutlet NSButton *titlepageToolbarButton;
@property (weak) IBOutlet NSButton *pagebreakToolbarButton;
@property (weak) IBOutlet NSButton *previewToolbarButton;
@property (weak) IBOutlet NSButton *printToolbarButton;
@property (weak) IBOutlet NSButton *pdfToolbarButton;

@property (strong) NSArray *toolbarButtons;

@property (strong, nonatomic) NSString *contentBuffer; //Keeps the text until the text view is initialized

@property (strong, nonatomic) NSFont *courier;
@property (strong, nonatomic) NSFont *boldCourier;
@property (strong, nonatomic) NSFont *italicCourier;

@property (strong, nonatomic) PrintView *printView; //To keep the asynchronously working print data generator in memory

@property (strong, nonatomic) ContinousFountainParser* parser;

@end

#define THEME_KEY @"Theme"

typedef enum : NSUInteger {
    light,
    dark,
    solarizedLight,
    solarizedDark
} Theme;

@implementation Document

#pragma mark - Document Basics

- (instancetype)init {
    self = [super init];
    if (self) {
        self.printInfo.topMargin = 25;
        self.printInfo.bottomMargin = 50;
    }
    return self;
}

#define TEXT_INSET 20

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
//    aController.window.titleVisibility = NSWindowTitleHidden; //Makes the title and toolbar unified by hiding the title
    self.toolbarButtons = @[_boldToolbarButton, _italicToolbarButton, _underlineToolbarButton, _ommitToolbarButton, _noteToolbarButton, _forceHeadingToolbarButton, _forceActionToolbarButton, _forceCharacterToolbarButton, _forceTransitionToolbarButton, _forceLyricsToolbarButton, _titlepageToolbarButton, _pagebreakToolbarButton, _previewToolbarButton, _printToolbarButton, _pdfToolbarButton];
    
    self.textView.textContainerInset = NSMakeSize(TEXT_INSET, TEXT_INSET);
    self.backgroundView.fillColor = [NSColor colorWithCalibratedRed:0.5
                                                              green:0.5
                                                               blue:0.5
                                                              alpha:1.0];
    [self.textView setFont:[self courier]];
    NSMutableDictionary *typingAttributes = [[NSMutableDictionary alloc] init];
    [typingAttributes setObject:[self courier] forKey:@"Font"];
    
    //Put any previously loaded data into the text view
    if (self.contentBuffer) {
        [self setText:self.contentBuffer];
    } else {
        [self setText:@""];
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [Document setTheme:[defaults integerForKey:THEME_KEY] writeToDefaults:NO];
    
    self.parser = [[ContinousFountainParser alloc] initWithString:[self getText]];
    [self applyFormatChanges];
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (NSString *)windowNibName {
    return @"Document";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSData *dataRepresentation = [[self getText] dataUsingEncoding:NSUTF8StringEncoding];
    return dataRepresentation;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    [self setText:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    return YES;
}

- (NSString *)getText
{
    return [self.textView string];
}

- (IBAction)printDocument:(id)sender
{
    self.printView = [[PrintView alloc] initWithDocument:self toPDF:NO];
}

- (IBAction)exportPDF:(id)sender
{
    self.printView = [[PrintView alloc] initWithDocument:self toPDF:YES];
}

- (void)updateWebView
{
    FNScript *script = [[FNScript alloc] initWithString:[self getText]];
    FNHTMLScript *htmpScript = [[FNHTMLScript alloc] initWithScript:script document:self];
    [[self.webView mainFrame] loadHTMLString:[htmpScript html] baseURL:nil];
}

- (void)setText:(NSString *)text
{
    if (!self.textView) {
        self.contentBuffer = text;
    } else {
        [self.textView setString:text];
        [self updateWebView];
    }
}




#pragma mark - Formatting

+ (void)setTheme:(Theme)theme writeToDefaults:(BOOL)write
{
    if (write) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:theme forKey:THEME_KEY];
    }
    
    NSArray* openDocuments = [[NSApplication sharedApplication] orderedDocuments];
    
    for (Document* doc in openDocuments) {
        switch (theme) {
            case light:
                [doc.textView setBackgroundColor:[NSColor colorWithWhite:1.0 alpha:1.0]];
                [doc.textView setTextColor:[NSColor colorWithWhite:0.0 alpha:1.0]];
                [doc.textView setInsertionPointColor:[NSColor colorWithWhite:0.1 alpha:1.0]];
                break;
                
            case dark:
                [doc.textView setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:1.0]];
                [doc.textView setTextColor:[NSColor colorWithWhite:1.0 alpha:1.0]];
                [doc.textView setInsertionPointColor:[NSColor colorWithWhite:0.9 alpha:1.0]];
                break;
                
            case solarizedLight:
                [doc.textView setBackgroundColor:[NSColor colorWithRed:0.99 green:0.969 blue:0.89 alpha:1.0]];
                [doc.textView setTextColor:[NSColor colorWithRed:0.345 green:0.427 blue:0.455 alpha:1.0]];
                [doc.textView setInsertionPointColor:[NSColor colorWithRed:0.396 green:0.482 blue:0.51 alpha:1.0]];
                break;
                
            case solarizedDark:
                [doc.textView setBackgroundColor:[NSColor colorWithRed:0.004 green:0.169 blue:0.208 alpha:1.0]];
                [doc.textView setTextColor:[NSColor colorWithRed:0.514 green:0.580 blue:0.584 alpha:1.0]];
                [doc.textView setInsertionPointColor:[NSColor colorWithRed:0.576 green:0.627 blue:0.631 alpha:1.0]];
                break;
        }
    }
}


- (void)textDidChange:(NSNotification *)notification
{
    //Get current line
    
    //Analyze current line
    
    //If forces -> force
    //If caps -> Character
    //If
    
    //Format it
    
    /* DIRTY METHOD UNTIL INCREMENTAL PARSE IS IMPLEMENTED */
    self.parser = [[ContinousFountainParser alloc] initWithString:[self getText]];
    [self applyFormatChanges];
}

- (void)formattAllLines
{
    for (Line* line in self.parser.lines) {
        [self formatLineOfScreenplay:line];
    }
    
}

- (void)applyFormatChanges
{
    for (NSNumber* index in self.parser.changedIndices) {
        Line* line = self.parser.lines[index.integerValue];
        [self formatLineOfScreenplay:line];
    }
}

#define CHARACTER_INDENT 270
#define PARENTHETICAL_INDENT 210
#define DIALOGUE_INDENT 150
#define DIALOGUE_RIGHT 450

#define DD_CHARACTER_INDENT 570
#define DD_PARENTHETICAL_INDENT 510
#define DOUBLE_DIALOGUE_INDENT 450
#define DD_RIGHT 750

- (void)formatLineOfScreenplay:(Line*)line
{
    NSUInteger begin = line.position;
    NSUInteger length = [line.string length];
    NSRange range = NSMakeRange(begin, length);
    
    NSDictionary *attributes = @{};
    
    if (line.type == heading || line.type == pageBreak) {
        attributes = @{NSFontAttributeName: [self boldCourier]};
        
    } else if (line.type == lyrics) {
        attributes = @{NSFontAttributeName: [self italicCourier]};
        
    } else if (line.type == titlePageTitle  ||
               line.type == titlePageAuthor ||
               line.type == titlePageCredit ||
               line.type == titlePageSource) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        [paragraphStyle setAlignment:NSTextAlignmentCenter];
        
        attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
        
    } else if (line.type == transition) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        [paragraphStyle setAlignment:NSTextAlignmentRight];
        
        attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
        
    } else if (line.type == centered) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        [paragraphStyle setAlignment:NSTextAlignmentCenter];
        
        attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
        
    } else if (line.type == character) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        [paragraphStyle setFirstLineHeadIndent:CHARACTER_INDENT];
        [paragraphStyle setHeadIndent:CHARACTER_INDENT];
        [paragraphStyle setTailIndent:DIALOGUE_RIGHT];
        
        attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
        
    } else if (line.type == parenthetical) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        [paragraphStyle setFirstLineHeadIndent:PARENTHETICAL_INDENT];
        [paragraphStyle setHeadIndent:PARENTHETICAL_INDENT];
        [paragraphStyle setTailIndent:DIALOGUE_RIGHT];
        
        attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
        
    } else if (line.type == dialogue) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        [paragraphStyle setFirstLineHeadIndent:DIALOGUE_INDENT];
        [paragraphStyle setHeadIndent:DIALOGUE_INDENT];
        [paragraphStyle setTailIndent:DIALOGUE_RIGHT];
        
        attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
        
    } else if (line.type == doubleDialogueCharacter) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        [paragraphStyle setFirstLineHeadIndent:DD_CHARACTER_INDENT];
        [paragraphStyle setHeadIndent:DD_CHARACTER_INDENT];
        [paragraphStyle setTailIndent:DD_RIGHT];
        
        attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
        
    } else if (line.type == doubleDialogueParenthetical) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        [paragraphStyle setFirstLineHeadIndent:DD_PARENTHETICAL_INDENT];
        [paragraphStyle setHeadIndent:DD_PARENTHETICAL_INDENT];
        [paragraphStyle setTailIndent:DD_RIGHT];
        
        attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
        
    } else if (line.type == doubleDialogue) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        [paragraphStyle setFirstLineHeadIndent:DOUBLE_DIALOGUE_INDENT];
        [paragraphStyle setHeadIndent:DOUBLE_DIALOGUE_INDENT];
        [paragraphStyle setTailIndent:DD_RIGHT];
        
        attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
        
    }
    
    //Maybe grey sections?
    
    NSTextStorage *textStorage = [self.textView textStorage];
    
    //Remove all former paragraph styles and overwrite fonts
    [textStorage removeAttribute:NSParagraphStyleAttributeName range:range];
    [textStorage addAttribute:NSFontAttributeName value:[self courier] range:range];
    
    //Add selected attributes
    [textStorage addAttributes:attributes range:range];
}

- (NSFont*)courier
{
    if (!_courier) {
        _courier = [NSFont fontWithName:@"Courier Prime" size:13];
    }
    return _courier;
}

- (NSFont*)boldCourier
{
    if (!_boldCourier) {
        _boldCourier = [NSFont fontWithName:@"Courier Prime Bold" size:13];
    }
    return _boldCourier;
}

- (NSFont*)italicCourier
{
    if (!_italicCourier) {
        _italicCourier = [NSFont fontWithName:@"Courier Prime Italic" size:13];
    }
    return _italicCourier;
}



#pragma mark - Formatting Buttons

static NSString *lineBreak = @"\n\n===\n\n";
static NSString *boldSymbol = @"**";
static NSString *italicSymbol = @"*";
static NSString *underlinedSymbol = @"_";
static NSString *noteOpen = @"[[";
static NSString *noteClose= @"]]";
static NSString *ommitOpen = @"/*";
static NSString *ommitClose= @"*/";
static NSString *forceHeadingSymbol = @".";
static NSString *forceActionSymbol = @"!";
static NSString *forceCharacterSymbol = @"@";
static NSString *forceTransitionSymbol = @">";
static NSString *forceLyricsSymbol = @"~";

- (NSString*)titlePage
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd.MM.yyyy"];
    return [NSString stringWithFormat:@"Title: \nCredit: \nAuthor: \nDraft date: %@\nContact: \n\n", [dateFormatter stringFromDate:[NSDate date]]];
}


- (IBAction)addTitlePage:(id)sender
{
    if ([self selectedTabViewTab] == 0) {
        if ([[self getText] length] < 6) {
            [self addString:[self titlePage] atIndex:0];
        } else if (![[[self getText] substringWithRange:NSMakeRange(0, 6)] isEqualToString:@"Title:"]) {
            [self addString:[self titlePage] atIndex:0];
        }
    }
}

- (IBAction)addPageBreak:(id)sender
{
    if ([self selectedTabViewTab] == 0) {
        NSRange cursorLocation = [self cursorLocation];
        if (cursorLocation.location != NSNotFound) {
            //Step forward to end of line
            NSUInteger location = cursorLocation.location + cursorLocation.length;
            NSUInteger length = [[self getText] length];
            while (true) {
                if (location == length) {
                    break;
                }
                NSString *nextChar = [[self getText] substringWithRange:NSMakeRange(location, 1)];
                if ([nextChar isEqualToString:@"\n"]) {
                    break;
                }
                
                location++;
            }
            self.textView.selectedRange = NSMakeRange(location, 0);
            [self addString:lineBreak atIndex:location];
        }
    }
}

- (void)addString:(NSString*)string atIndex:(NSUInteger)index
{
    [self.textView replaceCharactersInRange:NSMakeRange(index, 0) withString:string];
    [[[self undoManager] prepareWithInvocationTarget:self] removeString:string atIndex:index];
}

- (void)removeString:(NSString*)string atIndex:(NSUInteger)index
{
    [self.textView replaceCharactersInRange:NSMakeRange(index, [string length]) withString:@""];
    [[[self undoManager] prepareWithInvocationTarget:self] addString:string atIndex:index];
}


- (IBAction)makeBold:(id)sender
{
    //Check if the currently selected tab is the one for editing
    if ([self selectedTabViewTab] == 0) {
        //Retreiving the cursor location
        NSRange cursorLocation = [self cursorLocation];
        [self format:cursorLocation beginningSymbol:boldSymbol endSymbol:boldSymbol];
    }
}

- (IBAction)makeItalic:(id)sender
{
    //Check if the currently selected tab is the one for editing
    if ([self selectedTabViewTab] == 0) {
        //Retreiving the cursor location
        NSRange cursorLocation = [self cursorLocation];
        [self format:cursorLocation beginningSymbol:italicSymbol endSymbol:italicSymbol];
    }
}

- (IBAction)makeUnderlined:(id)sender
{
    //Check if the currently selected tab is the one for editing
    if ([self selectedTabViewTab] == 0) {
        //Retreiving the cursor location
        NSRange cursorLocation = [self cursorLocation];
        [self format:cursorLocation beginningSymbol:underlinedSymbol endSymbol:underlinedSymbol];
    }
}


- (IBAction)makeNote:(id)sender
{
    //Check if the currently selected tab is the one for editing
    if ([self selectedTabViewTab] == 0) {
        //Retreiving the cursor location
        NSRange cursorLocation = [self cursorLocation];
        [self format:cursorLocation beginningSymbol:noteOpen endSymbol:noteClose];
    }
}

- (IBAction)makeOmmitted:(id)sender
{
    //Check if the currently selected tab is the one for editing
    if ([self selectedTabViewTab] == 0) {
        //Retreiving the cursor location
        NSRange cursorLocation = [self cursorLocation];
        [self format:cursorLocation beginningSymbol:ommitOpen endSymbol:ommitClose];
    }
}

- (NSRange)cursorLocation
{
    return [[self.textView selectedRanges][0] rangeValue];
}


- (void)format:(NSRange)cursorLocation beginningSymbol:(NSString*)beginningSymbol endSymbol:(NSString*)endSymbol
{
    //Checking if the cursor location is vaild
    if (cursorLocation.location  + cursorLocation.length <= [[self getText] length]) {
        //Checking if the selected text is allready formated in the specified way
        NSString *selectedString = [self.textView.string substringWithRange:cursorLocation];
        NSInteger selectedLength = [selectedString length];
        NSInteger symbolLength = [beginningSymbol length] + [endSymbol length];

        NSUInteger addedCharacters = 0;
        
        if (selectedLength >= symbolLength &&
            [[selectedString substringToIndex:[beginningSymbol length]] isEqualToString:beginningSymbol] &&
            [[selectedString substringFromIndex:selectedLength - [endSymbol length]] isEqualToString:endSymbol]) {
            //The Text is formated, remove the formatting
            [self.textView replaceCharactersInRange:cursorLocation withString:[selectedString substringWithRange:NSMakeRange([beginningSymbol length], selectedLength - [beginningSymbol length] - [endSymbol length])]];
            //Put a corresponding undo action
            [[[self undoManager] prepareWithInvocationTarget:self] format:NSMakeRange(cursorLocation.location, cursorLocation.length - [beginningSymbol length] - [endSymbol length]) beginningSymbol:beginningSymbol endSymbol:endSymbol];
        } else {
            //The Text isn't formated, but let's alter the cursor range and check again because there might be formatting right outside the selected area
            NSRange modifiedCursorLocation = cursorLocation;
            if (cursorLocation.location >= [beginningSymbol length] && (cursorLocation.location + cursorLocation.length) <= ([[self getText] length] - [endSymbol length])) {
                if (modifiedCursorLocation.location + modifiedCursorLocation.length + [endSymbol length] - 1 <= [[self getText] length]) {
                    modifiedCursorLocation = NSMakeRange(modifiedCursorLocation.location - [beginningSymbol length], modifiedCursorLocation.length + [beginningSymbol length]  + [endSymbol length]);
                }
            }
            NSString *newSelectedString = [self.textView.string substringWithRange:modifiedCursorLocation];
            //Repeating the check from above
            if ([newSelectedString length] >= symbolLength && [[newSelectedString substringToIndex:[beginningSymbol length]] isEqualToString:beginningSymbol] && [[newSelectedString substringFromIndex:[newSelectedString length] - [endSymbol length]] isEqualToString:endSymbol]) {
                //The Text is formated outside of the original selection, remove!!!
                [self.textView replaceCharactersInRange:modifiedCursorLocation withString:[newSelectedString substringWithRange:NSMakeRange([beginningSymbol length], [newSelectedString length] - [beginningSymbol length] - [endSymbol length])]];
                [[[self undoManager] prepareWithInvocationTarget:self] format:NSMakeRange(modifiedCursorLocation.location, modifiedCursorLocation.length - [beginningSymbol length] - [endSymbol length]) beginningSymbol:beginningSymbol endSymbol:endSymbol];
            } else {
                //The text really isn't formatted. Just add the formatting using the original data.
                [self.textView replaceCharactersInRange:NSMakeRange(cursorLocation.location + cursorLocation.length, 0) withString:endSymbol];
                [self.textView replaceCharactersInRange:NSMakeRange(cursorLocation.location, 0) withString:beginningSymbol];
                [[[self undoManager] prepareWithInvocationTarget:self] format:NSMakeRange(cursorLocation.location, cursorLocation.length + [beginningSymbol length] + [endSymbol length]) beginningSymbol:beginningSymbol endSymbol:endSymbol];
                addedCharacters = [endSymbol length];
            }
        }
        self.textView.selectedRange = NSMakeRange(cursorLocation.location+cursorLocation.length+addedCharacters, 0);
    }
}

- (IBAction)forceHeading:(id)sender
{
    //Check if the currently selected tab is the one for editing
    if ([self selectedTabViewTab] == 0) {
        //Retreiving the cursor location
        NSRange cursorLocation = [self cursorLocation];
        [self forceLineType:cursorLocation symbol:forceHeadingSymbol];
    }
}

- (IBAction)forceAction:(id)sender
{
    //Check if the currently selected tab is the one for editing
    if ([self selectedTabViewTab] == 0) {
        //Retreiving the cursor location
        NSRange cursorLocation = [self cursorLocation];
        [self forceLineType:cursorLocation symbol:forceActionSymbol];
    }
}

- (IBAction)forceCharacter:(id)sender
{
    //Check if the currently selected tab is the one for editing
    if ([self selectedTabViewTab] == 0) {
        //Retreiving the cursor location
        NSRange cursorLocation = [self cursorLocation];
        [self forceLineType:cursorLocation symbol:forceCharacterSymbol];
    }
}

- (IBAction)forceTransition:(id)sender
{
    
    //Check if the currently selected tab is the one for editing
    if ([self selectedTabViewTab] == 0) {
        //Retreiving the cursor location
        NSRange cursorLocation = [self cursorLocation];
        [self forceLineType:cursorLocation symbol:forceTransitionSymbol];
    }
}

- (IBAction)forceLyrics:(id)sender
{
    //Check if the currently selected tab is the one for editing
    if ([self selectedTabViewTab] == 0) {
        //Retreiving the cursor location
        NSRange cursorLocation = [self cursorLocation];
        [self forceLineType:cursorLocation symbol:forceLyricsSymbol];
    }
}

- (void)forceLineType:(NSRange)cursorLocation symbol:(NSString*)symbol
{
    //Find the index of the first symbol of the line
    NSUInteger indexOfLineBeginning = cursorLocation.location;
    while (true) {
        if (indexOfLineBeginning == 0) {
            break;
        }
        NSString *characterBefore = [[self getText] substringWithRange:NSMakeRange(indexOfLineBeginning - 1, 1)];
        if ([characterBefore isEqualToString:@"\n"]) {
            break;
        }
        
        indexOfLineBeginning--;
    }
    NSRange firstCharacterRange;
    //If the cursor resides in an empty line
    //Which either happens because the beginning of the line is the end of the document
    //Or is indicated by the next character being a newline
    //The range for the first charate in line needs to be an empty string
    if (indexOfLineBeginning == [[self getText] length]) {
        firstCharacterRange = NSMakeRange(indexOfLineBeginning, 0);
    } else if ([[[self getText] substringWithRange:NSMakeRange(indexOfLineBeginning, 1)] isEqualToString:@"\n"]){
        firstCharacterRange = NSMakeRange(indexOfLineBeginning, 0);
    } else {
        firstCharacterRange = NSMakeRange(indexOfLineBeginning, 1);
    }
    NSString *firstCharacter = [[self getText] substringWithRange:firstCharacterRange];
    
    //If the line is already forced to the desired type, remove the force
    if ([firstCharacter isEqualToString:symbol]) {
        [self.textView replaceCharactersInRange:firstCharacterRange withString:@""];
    } else {
        //If the line is not forced to the desirey type, check if it is forced to be something else
        BOOL otherForce = NO;
        
        NSArray *allForceSymbols = @[forceActionSymbol, forceCharacterSymbol, forceHeadingSymbol, forceLyricsSymbol, forceTransitionSymbol];
        
        for (NSString *otherSymbol in allForceSymbols) {
            if (otherSymbol != symbol && [firstCharacter isEqualToString:otherSymbol]) {
                otherForce = YES;
                break;
            }
        }
        
        //If the line is forced to be something else, replace that force with the new force
        //If not, insert the new character before the first one
        if (otherForce) {
            [self.textView replaceCharactersInRange:firstCharacterRange withString:symbol];
        } else {
            [self.textView replaceCharactersInRange:firstCharacterRange withString:[symbol stringByAppendingString:firstCharacter]];
        }
    }
}



#pragma mark - Sharing Menu

//Empty function, which needs to exists to make the share button work.
- (IBAction)share:(id)sender {}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem.title isEqualToString:@"Share"]) {
        [menuItem.submenu removeAllItems];
        NSArray *services = @[];
        if (self.fileURL) {
            services = [NSSharingService sharingServicesForItems:@[self.fileURL]];
            
            for (NSSharingService *service in services) {
                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:service.title action:@selector(shareFromService:) keyEquivalent:@""];
                item.image = service.image;
                service.subject = [self.fileURL lastPathComponent];
                item.representedObject = service;
                [menuItem.submenu addItem:item];
            }
        }
        if ([services count] == 0) {
            NSMenuItem *noThingPleaseSaveItem = [[NSMenuItem alloc] initWithTitle:@"Please save the file to share" action:nil keyEquivalent:@""];
            noThingPleaseSaveItem.enabled = NO;
            [menuItem.submenu addItem:noThingPleaseSaveItem];
        }
        return YES;
    } else if ([menuItem.title isEqualToString:@"Print…"] || [menuItem.title isEqualToString:@"Export to PDF"]) {
        NSArray* words = [[self getText] componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString* visibleCharacters = [words componentsJoinedByString:@""];
        if ([visibleCharacters length] == 0) {
            return NO;
        }
    } else if ([menuItem.title isEqualToString:@"Light"]) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        Theme theme = [defaults integerForKey:THEME_KEY];
        if (theme == light) {
            [menuItem setState:NSOnState];
        } else {
            [menuItem setState:NSOffState];
        }
    } else if ([menuItem.title isEqualToString:@"Dark"]) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        Theme theme = [defaults integerForKey:THEME_KEY];
        if (theme == dark) {
            [menuItem setState:NSOnState];
        } else {
            [menuItem setState:NSOffState];
        }
    } else if ([menuItem.title isEqualToString:@"Solarized Light"]) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        Theme theme = [defaults integerForKey:THEME_KEY];
        if (theme == solarizedLight) {
            [menuItem setState:NSOnState];
        } else {
            [menuItem setState:NSOffState];
        }
    } else if ([menuItem.title isEqualToString:@"Solarized Dark"]) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        Theme theme = [defaults integerForKey:THEME_KEY];
        if (theme == solarizedDark) {
            [menuItem setState:NSOnState];
        } else {
            [menuItem setState:NSOffState];
        }
    }
    
    return YES;
}

- (IBAction)shareFromService:(id)sender
{
    [[sender representedObject] performWithItems:@[self.fileURL]];
}

#pragma mark - User Interaction

- (IBAction)preview:(id)sender
{
    if ([self selectedTabViewTab] == 0) {
        [self updateWebView];
        
        [self setSelectedTabViewTab:1];
        
        //Disable everything in the toolbar except print and preview and pdf
        for (NSButton *button in self.toolbarButtons) {
            if (button != _printToolbarButton && button != _previewToolbarButton && button != _pdfToolbarButton) {
                button.enabled = NO;
            }
        }
        
    } else {
        [self setSelectedTabViewTab:0];
        
        //Enable everything in the toolbar except print and preview and pdf
        for (NSButton *button in self.toolbarButtons) {
            if (button != _printToolbarButton && button != _previewToolbarButton && button != _pdfToolbarButton) {
                button.enabled = YES;
            }
        }
    }
}

- (NSUInteger)selectedTabViewTab
{
    return [self.tabView indexOfTabViewItem:[self.tabView selectedTabViewItem]];
}

- (void)setSelectedTabViewTab:(NSUInteger)index
{
    [self.tabView selectTabViewItem:[self.tabView tabViewItemAtIndex:index]];
}

- (IBAction)setLightMode:(id)sender
{
    [Document setTheme:light writeToDefaults:YES];
}

- (IBAction)setDarkMode:(id)sender
{
    [Document setTheme:dark writeToDefaults:YES];
}

- (IBAction)setSolarizedLightMode:(id)sender
{
    [Document setTheme:solarizedLight writeToDefaults:YES];
}

- (IBAction)setSolarizedDarkMode:(id)sender
{
    [Document setTheme:solarizedDark writeToDefaults:YES];
}

#pragma mark - Help

- (IBAction)showFountainSyntax:(id)sender
{
    [self openURLInWebBrowser:@"http://www.fountain.io/syntax#section-overview"];
}

- (IBAction)showFountainWebsite:(id)sender
{
    [self openURLInWebBrowser:@"http://www.fountain.io"];
}

- (IBAction)showWriterOnGitHub:(id)sender
{
    [self openURLInWebBrowser:@"https://github.com/HendrikNoeller/Writer-Mac"];
}

- (void)openURLInWebBrowser:(NSString*)urlString
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

@end
