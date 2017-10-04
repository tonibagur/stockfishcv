//
//  CameraVC.m
//  Stockfish
//
//  Created by Omar on 2/10/17.
//

#import "CameraVC.h"
#import "CaptureSessionManager.h"

@interface CameraVC () < CaptureSessionManagerDelegate>
{
    CaptureSessionManager *camManager;
    UIImage *lastPhoto;
}
// view Alpha Marks backgrounds
@property (weak, nonatomic) IBOutlet UIView *vMarkTop;
@property (weak, nonatomic) IBOutlet UIView *vMarkBottom;
@property (weak, nonatomic) IBOutlet UIView *vMarkSelectionPhoto;

// referent to camera
@property (weak, nonatomic) IBOutlet UIView *vCamera;
@property (weak, nonatomic) IBOutlet UIImageView *imgPhotoTaken;

// vConfirmPhoto
@property (weak, nonatomic) IBOutlet UIView *btnRepeat;
@property (weak, nonatomic) IBOutlet UIView *btnConfirm;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lcvConfirm_BOTTOM;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lcvConfirm_HEIGHT;


@end

@implementation CameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initCapture];
    [self setupUI];
    
}

- (void) initCapture
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!camManager) {
            camManager = [[CaptureSessionManager alloc] initWithFrame:[UIScreen mainScreen].bounds withDel:self withPresset:AVCaptureSessionPresetHigh];
        }
        [camManager startRunning];
        [self.vCamera.layer addSublayer:camManager.previewLayer];
        
    });
}

- (void) setupUI
{
    [self showHideBackgroundSelection:NO];
    [self showHideConfirm:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

#pragma mark - ActionButtons

- (IBAction)btnPhoto:(id)sender
{
    [camManager takePhoto];
    //[camManager stopRunning];
    //[self showHideConfirm:YES];
}

- (IBAction)btnRetake:(id)sender
{
    [camManager startRunning];
    [self showHideConfirm:NO];
}

- (IBAction)btnOkPhoto:(id)sender
{
    if (!lastPhoto)  {
        [camManager startRunning];
        [self showHideConfirm:NO];
        NSLog(@"Error: no image saved in memory");
        return;
        
    }
    
    self.imgPhotoTaken.image = lastPhoto;
    self.imgPhotoTaken.contentMode = UIViewContentModeScaleAspectFit;
    
    UIImage *screenImage = [self captureViewIn:self.imgPhotoTaken];
//     UIImageWriteToSavedPhotosAlbum(screenImage, nil, nil, nil);
//    NSLog(@"screenImage: %@", screenImage);
    
//    CGImageRef imgRef = screenImage.CGImage;
//    CGFloat width = CGImageGetWidth(imgRef);
//    CGFloat height = CGImageGetHeight(imgRef);
    
    CGFloat scaleScreen = [UIScreen mainScreen].scale;
    
        CGRect cropRect = self.vMarkSelectionPhoto.frame;
    
    cropRect = CGRectMake(self.vMarkSelectionPhoto.frame.origin.x * scaleScreen, self.vMarkSelectionPhoto.frame.origin.y*scaleScreen, self.vMarkSelectionPhoto.frame.size.width*scaleScreen, self.vMarkSelectionPhoto.frame.size.width*scaleScreen);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([screenImage CGImage], cropRect);
    
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:scaleScreen orientation:screenImage.imageOrientation];
  //  UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil);
    NSLog(@"finalImage: %@", finalImage);
    
    if ([self.delegate respondsToSelector:@selector(cameraDidSelectPhoto:)]) {
        
        [self.delegate cameraDidSelectPhoto:finalImage];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    /*
    CGRect rect = self.vCamera.bounds;
    
    CGImageRef imgRef = lastPhoto.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGFloat ratio = 1.0;
    
    if (rect.size.width > width) {
        ratio = rect.size.width / width;
    }
    else if (rect.size.width < width) {
        ratio = width / rect.size.width;
    }

    CGFloat proporcionPhoto = height / width; //  480/640  = 0.75
    CGFloat proporcionScreen = [UIScreen mainScreen].bounds.size.width / [UIScreen mainScreen].bounds.size.height; // 375/667 = 0.56221
    
    CGFloat conversionEntreFormatos = proporcionPhoto / proporcionScreen;  // 0.75 / 0.56221 = 1.33402
    */
//    rect = [UIScreen mainScreen].bounds;
//
//    if (rect.size.width > width) {
//        ratio = rect.size.width / width;
//    }
//    else if (rect.size.width < width) {
//        ratio = width / rect.size.width;
//    }
//
    
    //ratio = ratio * conversionEntreFormatos;
    /*
    CGRect mark = self.vMarkSelectionPhoto.frame;
    
    CGRect cropRect = CGRectMake((mark.origin.x * conversionEntreFormatos) * ratio, (mark.origin.y * conversionEntreFormatos)* ratio, mark.size.width * ratio, mark.size.width * ratio);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([lastPhoto CGImage], cropRect);

    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1 orientation:lastPhoto.imageOrientation];
    UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil);
    */
    
 //   UIImageWriteToSavedPhotosAlbum(lastPhoto, nil, nil, nil);
    
    
    
    
    [camManager startRunning];
    [self showHideConfirm:NO];
}


- (UIImage *)captureViewIn:(UIView*)view {
    
    //hide controls if needed
    CGRect rect = [view bounds];
    
 //   UIGraphicsBeginImageContext(rect.size);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [view.layer renderInContext:context];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
    
}

- (UIImage *)captureView {
    
    //hide controls if needed
    CGRect rect = [self.view bounds];
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
    
}



- (IBAction)btnClose:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helpers animation

- (void) showHideBackgroundSelection:(BOOL) showDark
{
    CGFloat alpha = 0.7;
    if (showDark) alpha = 0.9;
    
    self.vMarkTop.alpha = self.vMarkBottom.alpha = alpha;
}

- (void) showHideConfirm:(BOOL) show
{
    if (show) self.lcvConfirm_BOTTOM.constant = 0;
    else {
        self.imgPhotoTaken.hidden = YES;
        self.lcvConfirm_BOTTOM.constant = -self.lcvConfirm_HEIGHT.constant;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - CaptureSessionManager delegate

- (void) CaptureSessionManagerDelegate_PhotoTaked:(UIImage*) photo
{
    if (!photo) {
        lastPhoto = nil;
        return;
        
    }
    
    lastPhoto = photo;
    
    [camManager stopRunning];
    [self showHideConfirm:YES];
    NSLog(@"fpoto: %@", photo);
    self.imgPhotoTaken.image = photo;
    self.imgPhotoTaken.hidden = NO;
}

- (void) dealloc
{
    NSLog(@"de alloc CameraVC");
}
- (void) CaptureSessionManagerDelegate_PhotoFailed {}
- (void) CaptureSessionManagerDelegate_EndProcessCIImage {}
- (void) showNotAuthorizeAudio:(BOOL) isAudio isCamera:(BOOL) isCamera isGalery:(BOOL) isGalery {}

- (void) CaptureSessionManagerDelegate_DidFinishVideoRecording:(NSURL*) url {}
- (void) CaptureSessionStartTimerVideo {}

@end
