//
//  AITacticWallAlways.h
//  WizardWar
//
//  Created by Sean Hess on 8/25/13.
//  Copyright (c) 2013 Orbital Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AITactic.h"

// Unlike WallRenew, this waits until it drops to 0, then switches to a different wall.
// Always makes sure it has a wall up!

@interface AITacticWallAlways : NSObject <AITactic>
@property (nonatomic, strong) NSArray * walls;
+(id)walls:(NSArray*)walls;
@end