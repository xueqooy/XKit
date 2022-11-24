//
//  OHuman.m
//  EDKit_Example
//
//  Created by 🌊 薛 on 2022/10/18.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "OHuman.h"
@import EDKit;

@implementation OHuman

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RuntimeObjc exchangeImplementations:OHuman.class originSelector:@selector(walk) newSelector:@selector(swizzle_walk)];
    });
}

- (void)walk {
    NSLog(@"OHuman walk");
}

- (void)swizzle_walk {
    NSLog(@"OHuman swizzle walk");
}

@end
