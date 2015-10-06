//
//  Document.m
//  Writer
//
//  Created by Hendrik Noeller on 05.10.14.
//  Copyright (c) 2015 Hendrik Noeller. All rights reserved.
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

#import "Document.h"
#import <WebKit/WebKit.h>
#import "FNScript.h"
#import "FNHTMLScript.h"
#import "PrintView.h"
#import "ColorView.h"

@interface Document ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (unsafe_unretained) IBOutlet WebView *webView;
@property (unsafe_unretained) IBOutlet NSTabView *tabView;
@property (weak) IBOutlet ColorView *backgroundView;

@property (strong, nonatomic) NSFont *courier;

@property (strong, nonatomic) PrintView *printView;
@end

@implementation Document

#pragma mark - Document Basics

- (instancetype)init {
    self = [super init];
    if (self) {
        self.documentContent = [[NSMutableString alloc] init];
        self.printInfo.topMargin = 25;
        self.printInfo.bottomMargin = 50;
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    [self updateTextView];
    self.textView.textContainerInset = NSMakeSize(20, 20);
    self.backgroundView.fillColor = [NSColor colorWithCalibratedRed:0.5
                                                              green:0.5
                                                               blue:0.5
                                                              alpha:1.0];
    [self.textView setFont:[self courier]];
    NSMutableDictionary *typingAttributes = [[NSMutableDictionary alloc] init];
    [typingAttributes setObject:[self courier] forKey:@"Font"];
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
    NSData *dataRepresentation = [self.documentContent dataUsingEncoding:NSUTF8StringEncoding];
    return dataRepresentation;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    self.documentContent = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] mutableCopy];
    return YES;
}

- (IBAction)printDocument:(id)sender
{
    self.printView = [[PrintView alloc] initWithDocument:self];
}



#pragma mark - View and Model Syncing

- (void)updateDocumentContent
{
    _documentContent = [[self.textView string] mutableCopy];
}

- (void)updateTextView
{
    [self.textView setString:[self.documentContent copy]];
}

- (void)updateWebView
{
    FNScript *scrit = [[FNScript alloc] initWithString:_documentContent];
    FNHTMLScript *htmpScript = [[FNHTMLScript alloc] initWithScript:scrit document:self];
    [[self.webView mainFrame] loadHTMLString:[htmpScript html] baseURL:nil];
}


- (void)setDocumentContent:(NSMutableString *)documentContent
{
    _documentContent = documentContent;
    [self updateTextView];
    [self updateWebView];
}

- (void)textDidChange:(NSNotification *)notification
{
    [self updateDocumentContent];
}

- (NSFont*)courier
{
    if (!_courier) {
        _courier = [NSFont fontWithName:@"Courier" size:13];
    }
    return _courier;
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
- (NSString*)titlePage
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd.MM.yyyy"];
    return [NSString stringWithFormat:@"Title: \nCredit: \nAuthor: \nDraft date: %@\nContact: \n\n", [dateFormatter stringFromDate:[NSDate date]]];
}


- (IBAction)addTitlePage:(id)sender
{
    if ([self selectedTabViewTab] == 0) {
        if ([self.documentContent length] < 6) {
            [self addString:[self titlePage] atIndex:0];
        } else if (![[self.documentContent substringWithRange:NSMakeRange(0, 6)] isEqualToString:@"Title:"]) {
            [self addString:[self titlePage] atIndex:0];
        }
    }
}

- (IBAction)addPageBreak:(id)sender
{
    if ([self selectedTabViewTab] == 0) {
        NSRange cursorLocation = [self cursorLocation];
        if (cursorLocation.location != NSNotFound) {
            [self addString:lineBreak atIndex:cursorLocation.location + cursorLocation.length];
        }
    }
}

- (void)addString:(NSString*)string atIndex:(NSUInteger)index
{
    [self.textView replaceCharactersInRange:NSMakeRange(index, 0) withString:string];
    [[[self undoManager] prepareWithInvocationTarget:self] removeString:string atIndex:index];
    [self textDidChange:[[NSNotification alloc] init]];
}

- (void)removeString:(NSString*)string atIndex:(NSUInteger)index
{
    [self.textView replaceCharactersInRange:NSMakeRange(index, [string length]) withString:@""];
    [[[self undoManager] prepareWithInvocationTarget:self] addString:string atIndex:index];
    [self textDidChange:[[NSNotification alloc] init]];
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
    if (cursorLocation.location  + cursorLocation.length <= [[self.textView string] length]) {
        //Checking if the selected text is allready formated in the specified way
        NSString *selectedString = [self.textView.string substringWithRange:cursorLocation];

        NSUInteger addedCharacters = 0;
        
        if ([selectedString length] >= [beginningSymbol length] + [endSymbol length] && [[selectedString substringToIndex:[beginningSymbol length]] isEqualToString:beginningSymbol] && [[selectedString substringFromIndex:[selectedString length] - [endSymbol length]] isEqualToString:endSymbol]) {
            //The Text is formated, remove!!!
            [self.textView replaceCharactersInRange:cursorLocation withString:[selectedString substringWithRange:NSMakeRange([beginningSymbol length], [selectedString length] - [beginningSymbol length] - [endSymbol length])]];
            [[[self undoManager] prepareWithInvocationTarget:self] format:NSMakeRange(cursorLocation.location, cursorLocation.length - [beginningSymbol length] - [endSymbol length]) beginningSymbol:beginningSymbol endSymbol:endSymbol];
        } else {
            //The Text isn't formated, but let's alter the cursor range and check again because there might be formatting right outside the selected area
            NSRange modifiedCursorLocation = cursorLocation;
            if (cursorLocation.location >= [beginningSymbol length] && (cursorLocation.location + cursorLocation.length) <= ([[self.textView string] length] - [endSymbol length])) {
                if (modifiedCursorLocation.location + modifiedCursorLocation.length + [endSymbol length] - 1 <= [[self.textView string] length]) {
                    modifiedCursorLocation = NSMakeRange(modifiedCursorLocation.location - [beginningSymbol length], modifiedCursorLocation.length + [beginningSymbol length]  + [endSymbol length]);
                }
            }
            NSString *newSelectedString = [self.textView.string substringWithRange:modifiedCursorLocation];
            //Repeating the check from above
            if ([newSelectedString length] >= [beginningSymbol length] + [endSymbol length] && [[newSelectedString substringToIndex:[beginningSymbol length]] isEqualToString:beginningSymbol] && [[newSelectedString substringFromIndex:[newSelectedString length] - [endSymbol length]] isEqualToString:endSymbol]) {
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
        [self textDidChange:[[NSNotification alloc] init]];
        self.textView.selectedRange = NSMakeRange(cursorLocation.location+cursorLocation.length+addedCharacters, 0);
    }
}



#pragma mark - Sharing Menu

- (IBAction)share:(id)sender
{
    
}

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
    } else {
        [self setSelectedTabViewTab:0];
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
