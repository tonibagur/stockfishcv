//
//  Utils.m
//  Stockfish
//
//  Created by Omar on 3/10/17.
//

#import "Utils.h"

@implementation Utils

+ (void) validateExistFolderAudio {}

// DIRECTORY
// *******************

+ (NSString*) getDirectory
{
    return NSTemporaryDirectory();
}

// Image
// *******************


+ (UIImage *) rotationImage:(UIImage*) image
{
    UIImage *normalizedImage;
    
    if (image.imageOrientation != UIImageOrientationUp)
    {
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        [image drawInRect:(CGRect){0, 0, image.size}];
        normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    else
    {
        normalizedImage = image;
    }
    return normalizedImage;
}

+ (UIImage* ) scaleImage:(UIImage *)image toMaxResolution:(int)resolution withRotation:(UIImageOrientation)orientation
{
    UIImage *newImage = [self rotationImage:image withImageOrientation:orientation];
    return [self onlyScaleImage:newImage toMaxResolution:resolution];
}

+ (UIImage *) scaleImage:(UIImage*)image toMaxResolution:(int)resolution
{
    UIImage *newImage = [self rotationImage:image];
    return [self onlyScaleImage:newImage toMaxResolution:resolution];
}

+ (UIImage *) rotationImage:(UIImage*) image withImageOrientation:(UIImageOrientation)orientation
{
    UIImage *normalizedImage;
    
    if (image.imageOrientation != UIImageOrientationUp)
    {
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        [image drawInRect:(CGRect){0, 0, image.size}];
        normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    else
    {
        normalizedImage = image;
    }
    return normalizedImage;
    
    //  UIGraphicsBeginImageContextWithOptio
}

+ (UIImage *) onlyScaleImage:(UIImage*)image toMaxResolution:(int) resolution
{
    if (!image) return nil;
    //imagen rotada correctamente
    
    // CGImageRef imgRef = [[self rotationImage:image] CGImage];
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    if (resolution<4) resolution=kMaxResolutionProfileUser;
    
    //escalamos a tamaño máximo
    
    if (width>resolution || height>resolution)
    {
        CGSize newSize;
        float ratio;
        
        if (width>height)
        {
            ratio=width/resolution;
            newSize=CGSizeMake(resolution, height/ratio );
        }
        else if (width<height)
        {
            ratio=height/resolution;
            newSize=CGSizeMake(width/ratio, resolution);
        }
        else
        {
            //image cuadrada
            newSize=CGSizeMake((float) resolution, (float) resolution);
        }
        
        float cutOffset = 2.5;
        if (resolution < 185.0){ //kMaxThumbnailEmojiCV+2) {
            cutOffset = 0;
        }
        
        
        UIGraphicsBeginImageContext(CGSizeMake(newSize.width-(cutOffset*2), newSize.height-(cutOffset*2)));
        [image drawInRect:CGRectMake(0, 0, newSize.width-(cutOffset*0), newSize.height-(cutOffset*0))];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        //una vez escalada la imagen al máximo, devolvemos el CROP
        
        return newImage;
        
    }
    else
    {
        //como el tamaño es inferior al máximo, devolvemos el CROP del original
        
        return image;
    }
}

@end
