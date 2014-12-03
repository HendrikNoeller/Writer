//
//  PrintView.h
//  Writer
//
//  Created by Hendrik Noeller on 06.10.14.
//  Copyright (c) 2014 Hendrik Noeller. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"
#import <WebKit/WebKit.h>

@interface PrintView : NSView

- (id)initWithDocument:(Document*)document;

@end
