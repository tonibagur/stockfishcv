//
//  Utils.h
//  Stockfish
//
//  Created by Omar on 3/10/17.
//

#import <Foundation/Foundation.h>

#define kMaxResolutionProfileUser 400.0

@interface Utils : NSObject

+ (void) validateExistFolderAudio;
+ (NSString*) getDirectory;
+ (UIImage*) scaleImage:(UIImage*)image toMaxResolution:(int)resolution;
+ (UIImage *) onlyScaleImage:(UIImage*)image toMaxResolution:(int) resolution;
+ (UIImage* ) scaleImage:(UIImage *)image toMaxResolution:(int)resolution withRotation:(UIImageOrientation)orientation;


@end
