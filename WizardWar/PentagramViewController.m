//
//  PentagramViewController.m
//  WizardWar
//
//  Created by Dallin Skinner on 5/17/13.
//  Copyright (c) 2013 WizardWar. All rights reserved.
//

#import "PentagramViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Elements.h"
#import "NSArray+Functional.h"
#import "UIColor+Hex.h"
#import "AppStyle.h"
#import "SpellFail.h"
#import <ReactiveCocoa.h>

#define RECHARGE_INTERVAL 2.5

@interface PentagramViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *pentagram;

@property (weak, nonatomic) IBOutlet PentEmblem *windEmblem;
@property (weak, nonatomic) IBOutlet PentEmblem *fireEmblem;
@property (weak, nonatomic) IBOutlet PentEmblem *earthEmblem;
@property (weak, nonatomic) IBOutlet PentEmblem *waterEmblem;
@property (weak, nonatomic) IBOutlet PentEmblem *heartEmblem;

@property (weak, nonatomic) DrawingLayer *drawingLayer;

@property (weak, nonatomic) PentEmblem *currentEmblem;
@property (copy, nonatomic) NSArray *emblems;
@property (weak, nonatomic) IBOutlet DACircularProgressView *waitProgress;

@property (strong, nonatomic) NSTimer * castTimer;
@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;
@property (nonatomic) CGFloat castDelayProgress;
@property (nonatomic) BOOL castDisabled;

@property (nonatomic) CGSize emblemSize;

@property (nonatomic) BOOL showHelp;

@end

@implementation PentagramViewController

- (void)viewDidLoad
{
    NSAssert(self.combos, @"PentagramViewController requires combos");
    
    [super viewDidLoad];
    [self.view setMultipleTouchEnabled:YES];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.clipsToBounds = YES;
    
    DrawingLayer *drawLayer = [[DrawingLayer alloc] initWithFrame:self.view.bounds];
    self.drawingLayer = drawLayer;
    drawLayer.backgroundColor = [UIColor clearColor];
    self.drawingLayer.points = [[NSMutableArray alloc] init];
    [self.view insertSubview:self.drawingLayer atIndex:0];
    [self setUpPentagram];
    
//    self.waitProgress.roundedCorners = NO;
////    self.waitProgress.trackTintColor = [UIColor colorWithRed:0 green:0.0 blue:0 alpha:0.4];
//    self.waitProgress.trackTintColor = [UIColor colorWithRed:0 green:0.0 blue:0 alpha:0.0];
//    self.waitProgress.progressTintColor = [UIColor colorWithRed:0.5 green:0.7 blue:1.0 alpha:0.6]; // [UIColor colorFromRGB:0xA3C7E7];
//    self.waitProgress.progress = 0.4;
    self.waitProgress.alpha = 0.0;
//    self.waitProgress.thicknessRatio = 1.0;
    
    self.feedbackLabel.font = [UIFont fontWithName:FONT_COMIC_ZINE_SOLID size:36];
    self.feedbackLabel.alpha = 0.0;
}

- (void)setUpPentagram
{
    self.fireEmblem.element = Fire;
    self.fireEmblem.status = EmblemStatusNormal;
    self.fireEmblem.mana = MAX_MANA;
    self.fireEmblem.image = [UIImage imageNamed:@"pentagram-fire.png"];
//    self.fireEmblem.size = self.emblemSize;
    
    self.heartEmblem.element = Heart;
    self.heartEmblem.status = EmblemStatusNormal;
    self.heartEmblem.mana = MAX_MANA;
    self.heartEmblem.image = [UIImage imageNamed:@"pentagram-heart.png"];
//    self.heartEmblem.size = self.emblemSize;
    
    self.waterEmblem.element = Water;
    self.waterEmblem.status = EmblemStatusNormal;
    self.waterEmblem.mana = MAX_MANA;
    self.waterEmblem.image = [UIImage imageNamed:@"pentagram-water.png"];
//    self.waterEmblem.size = self.emblemSize;
    
    self.earthEmblem.element = Earth;
    self.earthEmblem.status = EmblemStatusNormal;
    self.earthEmblem.mana = MAX_MANA;
    self.earthEmblem.image = [UIImage imageNamed:@"pentagram-earth.png"];
//    self.earthEmblem.size = self.emblemSize;
    
    self.windEmblem.element = Air;
    self.windEmblem.status = EmblemStatusNormal;
    self.windEmblem.mana = MAX_MANA;
    self.windEmblem.image = [UIImage imageNamed:@"pentagram-wind"];
//    self.windEmblem.size = self.emblemSize;
    
    self.emblems = [NSArray arrayWithObjects: self.fireEmblem, self.heartEmblem, self.waterEmblem, self.earthEmblem, self.windEmblem, nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)checkSelectedEmblems:(CGPoint)point {
    
    PentEmblem * emblem = [self.emblems find:^BOOL(PentEmblem*emblem) {
        return CGRectContainsPoint(emblem.frame, point);
    }];
    
    if (emblem && emblem != self.currentEmblem) {
        [self.drawingLayer.points replaceObjectAtIndex: ([self.drawingLayer.points count] - 1) withObject:[NSValue valueWithCGPoint:CGPointMake((emblem.frame.origin.x + (emblem.frame.size.width / 2)), (emblem.frame.origin.y + (emblem.frame.size.height / 2)))]];
        
        [self.drawingLayer.points addObject:[NSValue valueWithCGPoint:point]];
        
        self.currentEmblem = emblem;
        emblem.status = EmblemStatusSelected;
        
        [self.combos moveToElement:emblem.element];
        [self renderFeedback];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"TOUCHES BEGAN");
    self.showHelp = NO;
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UITouch *touch = obj;
        CGPoint touchPoint = [touch locationInView:self.view];
        [self.drawingLayer.points addObject: [NSValue valueWithCGPoint:touchPoint]];
        [self checkSelectedEmblems:touchPoint];
    }];
    
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    self.showHelp = NO;    
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        UITouch *touch = obj;
        CGPoint touchPoint = [touch locationInView:self.view];
        
        // what if it is 0?
        if ([self.drawingLayer.points count] <= 1) {
            // [self.drawingLayer.points replaceObjectAtIndex:1 withObject:[NSValue valueWithCGPoint:touchPoint]];
            [self.drawingLayer.points addObject: [NSValue valueWithCGPoint:touchPoint]];
        } else {
            [self.drawingLayer.points replaceObjectAtIndex:([self.drawingLayer.points count]-1) withObject:[NSValue valueWithCGPoint:touchPoint]];
        }

        [self.drawingLayer setNeedsDisplay];
        
        [self checkSelectedEmblems:touchPoint];
    }];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // If they only tapped, show the help stuff!
    self.showHelp = (self.combos.allElements.count <= 2);
    
    for(PentEmblem *emblem in self.emblems)
    {
        emblem.status = EmblemStatusNormal;
    }
    
    self.drawingLayer.points = [[NSMutableArray alloc] init];
    [self.drawingLayer setNeedsDisplay];
    
    self.currentEmblem = nil;
    
    [self.combos releaseElements];
    [self renderFeedback];    
}

-(void)setCastDelayProgress:(CGFloat)progress {
    _castDelayProgress = progress;
    self.waitProgress.progress = progress;
    self.waitProgress.progress = 0.0;
    self.waitProgress.alpha = 0.0;
    
    for(PentEmblem *emblem in self.emblems)
    {
        emblem.enabledProgress = progress;
    }
}


-(void)delayCast:(NSTimeInterval)delay {
    if (delay == 0) return;  
    NSTimeInterval tickTime = 0.05;
    CGFloat percentIncreasePerTick = tickTime / delay;
    self.castTimer = [NSTimer scheduledTimerWithTimeInterval:tickTime target:self selector:@selector(onCastTimer:) userInfo:@(percentIncreasePerTick) repeats:YES];
    [self setCastDelayProgress:0.0];
    self.castDisabled = YES;
    
    for(PentEmblem *emblem in self.emblems)
    {
        emblem.status = EmblemStatusDisabled;
    }    
}

-(void)onCastTimer:(NSTimer*)timer {
    NSNumber * percentIncreasePerTick = timer.userInfo;
    self.castDelayProgress += percentIncreasePerTick.floatValue;
    
    if (self.castDelayProgress >= 1.0) {
        self.castDisabled = NO;
        [self.castTimer invalidate];
        self.castTimer = nil;
        
        for(PentEmblem *emblem in self.emblems)
        {
            if (emblem.status == EmblemStatusDisabled)
                emblem.status = EmblemStatusNormal;
        }
        
//        [UIView animateWithDuration:0.2 animations:^{
//            self.waitProgress.alpha = 0.0;
//        }];
        
        [self renderFeedback];
    }
}

-(void)renderFeedback {
    BOOL hasHintedSpell = (self.combos.hintedSpell != nil);
    BOOL showNoMana = (!self.combos.castSpell && self.combos.hasElements && self.castDisabled);
//    BOOL showMisfire = (self.castDisabled && [self.combos.castSpell isKindOfClass:[SpellFail class]]);
    BOOL showMisfire = (self.castDisabled && self.combos.didMisfire);
    
    if (self.showHelp) {
        self.feedbackLabel.text = @"Connect 3 Elements";
        [UIView animateWithDuration:0.2 animations:^{
            self.feedbackLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self flashFeedback:1];
        }];
        
//        for(PentEmblem *emblem in self.emblems)
//        {
//            [emblem flashHighlight];
//        }

    } else if (hasHintedSpell || showNoMana) {
        if (showNoMana) {
            self.feedbackLabel.textColor = [AppStyle redErrorColor];
            [self.feedbackLabel setText:@"No Mana!"];
        } else {
            self.feedbackLabel.textColor = [UIColor whiteColor];            
            [self.feedbackLabel setText:self.combos.hintedSpell.name];
        }
        
        [UIView animateWithDuration:0.2 animations:^{
            self.feedbackLabel.alpha = 1.0;
        }];
    } else if(showMisfire) {
        self.feedbackLabel.textColor = [AppStyle redErrorColor];
        [self.feedbackLabel setText:@"Misfire!"];

        // this is because there's no event that says it should STOP, I'm just making it up
        // The cast delay finishes, and then what. 
        [UIView animateWithDuration:0.2 animations:^{
            self.feedbackLabel.alpha = 1.0;
        }];
    } else {
        [UIView animateWithDuration:0.8 animations:^{
            self.feedbackLabel.alpha = 0.0;
        }];
    }
}

-(void)flashFeedback {
    [UIView animateWithDuration:0.2 animations:^{
        self.feedbackLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            self.feedbackLabel.alpha = 0.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                self.feedbackLabel.alpha = 1.0;
            } completion:^(BOOL finished) {
                
            }];
        }];
    }];
}

// always ends ON
-(void)flashFeedback:(NSInteger)times {
    [UIView animateWithDuration:0.2 animations:^{
        self.feedbackLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            self.feedbackLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            if (times > 0) {
                [self flashFeedback:times-1];
            }
        }];
    }];
}

-(void)showHelpMessage {
    self.showHelp = YES;
    [self renderFeedback];
}

-(void)setCastDisabled:(BOOL)castDisabled {
    _castDisabled = castDisabled;
    self.combos.castDisabled = castDisabled;
    self.drawingLayer.castDisabled = castDisabled;
}

@end
