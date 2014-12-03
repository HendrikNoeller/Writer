//
//  ColorView.m
//  Writer
//
//  Created by Hendrik Noeller on 06.10.14.
//  Copyright (c) 2014 Hendrik Noeller. All rights reserved.
//

#import "ColorView.h"

@implementation ColorView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    if (self.fillColor) {
        [self.fillColor setFill];
        NSRectFill(dirtyRect);
    }
    
}

@end
