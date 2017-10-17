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
@property (weak, nonatomic) IBOutlet UIButton *btnGallery;
@property (weak, nonatomic) IBOutlet UIButton *btnFullGallery;

@end

@implementation CameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initCapture];
    //[self setupUI];
}

- (void) initCapture
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!camManager) {
            camManager = [[CaptureSessionManager alloc] initWithFrame:[UIScreen mainScreen].bounds withDel:self withPresset:AVCaptureSessionPresetHigh];
            
            [camManager startRunning];
        
        [self.vCamera.layer addSublayer:camManager.previewLayer];
            [self setupUI];
        }
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
}

- (IBAction)btnRetake:(id)sender
{
    [camManager startRunning];
    [self showHideConfirm:NO];
}

- (IBAction)btnSaveGallery:(id)sender
{
    UIImage *img = [self getImageCropScreen];
    if (img) {
        UIImage *small = [Utils onlyScaleImage:img toMaxResolution:400];
        if (small) {
            UIImageWriteToSavedPhotosAlbum(small, nil, nil, nil);
        }
        
    }
}

- (IBAction)btnSaveFull:(id)sender
{
    if (!lastPhoto)  {
        NSLog(@"Error: no image saved in memory");
        return ;
    }
    
    self.imgPhotoTaken.image = lastPhoto;
    self.imgPhotoTaken.contentMode = UIViewContentModeScaleAspectFit;
    
    UIImage *screenImage = [self captureViewIn:self.imgPhotoTaken];
    UIImageWriteToSavedPhotosAlbum(screenImage, nil, nil, nil);
    
}

- (UIImage*) getImageCropScreen
{
    if (!lastPhoto)  {
        [camManager startRunning];
        [self showHideConfirm:NO];
        NSLog(@"Error: no image saved in memory");
        return nil;
        
    }
    
    self.imgPhotoTaken.image = lastPhoto;
    self.imgPhotoTaken.contentMode = UIViewContentModeScaleAspectFit;
    
    UIImage *screenImage = [self captureViewIn:self.imgPhotoTaken];
    
    CGFloat scaleScreen = [UIScreen mainScreen].scale;
    
    CGRect cropRect = self.vMarkSelectionPhoto.frame;
    
    cropRect = CGRectMake(self.vMarkSelectionPhoto.frame.origin.x * scaleScreen, self.vMarkSelectionPhoto.frame.origin.y*scaleScreen, self.vMarkSelectionPhoto.frame.size.width*scaleScreen, self.vMarkSelectionPhoto.frame.size.width*scaleScreen);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([screenImage CGImage], cropRect);
    
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:scaleScreen orientation:screenImage.imageOrientation];

    
    return finalImage;
}

- (IBAction)btnOkPhoto:(id)sender
{
    
    UIImage *finalImage = [self getImageCropScreen];
    
    if (finalImage && [self.delegate respondsToSelector:@selector(cameraDidSelectPhoto:)]) {
        
        [self.delegate cameraDidSelectPhoto:finalImage];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    //[camManager startRunning];
    //[self showHideConfirm:NO];
}


- (UIImage *)captureViewIn:(UIView*)view
{
    //hide controls if needed
    CGRect rect = [view bounds];
    
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
    if (show) {
        self.lcvConfirm_BOTTOM.constant = 0;
        self.btnGallery.hidden = self.btnFullGallery.hidden = NO;
    }
    else {
        self.btnGallery.hidden = self.btnFullGallery.hidden = YES;
        self.lcvConfirm_BOTTOM.constant = -self.lcvConfirm_HEIGHT.constant;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
        [self showHideBackgroundSelection:show];
    }];
}

#pragma mark - CaptureSessionManager delegate

- (void) CaptureSessionManagerDelegate_PhotoTaked:(UIImage*) photo
{
    if (!photo) {
        lastPhoto = nil;
        return;
    }
    self.imgPhotoTaken.frame = self.vCamera.bounds;
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
