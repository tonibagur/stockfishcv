//
//  CameraVC.m
//  Stockfish
//
//  Created by Omar on 2/10/17.
//

#import "CameraVC.h"
#import "CaptureSessionManager.h"
#import "CoreMLManager.h"

@interface CameraVC () < CaptureSessionManagerDelegate>
{
    CaptureSessionManager *camManager;
    UIImage *lastPhoto;
    UIImage *photoResult;
}

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
}

- (void) initCapture
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!camManager) {
            camManager = [[CaptureSessionManager alloc] initWithFrame:[UIScreen mainScreen].bounds withDel:self withPresset:AVCaptureSessionPreset640x480];
            
            [camManager startRunning];
            
            [self.vCamera.layer addSublayer:camManager.previewLayer];
            [self setupUI];
        }
    });
}

- (void) setupUI
{
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
    lastPhoto = nil;
    photoResult = nil;
    
    self.imgPhotoTaken.image = nil;
    self.imgPhotoTaken.hidden = YES;
    
    [camManager startRunning];
    [self showHideConfirm:NO];
}

- (IBAction)btnSaveGallery:(id)sender
{
    if (!photoResult) {
        NSLog(@"Error: no image cropped result");
        return;
    }
    UIImageWriteToSavedPhotosAlbum(photoResult, nil, nil, nil);
}

- (IBAction)btnSaveFull:(id)sender
{
    if (!lastPhoto)  {
        NSLog(@"Error: no image saved in memory");
        return ;
    }
    
    UIImageWriteToSavedPhotosAlbum(lastPhoto, nil, nil, nil);
}

- (IBAction)btnOkPhoto:(id)sender
{
    if (!photoResult) {
        NSLog(@"error: no photo crop result");
        return;
    }
    UIImage *finalImage = photoResult;
    
    if (finalImage && [self.delegate respondsToSelector:@selector(cameraDidSelectPhoto:)])
    {
        [self.delegate cameraDidSelectPhoto:finalImage];
        [self dismissViewControllerAnimated:YES completion:nil];
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
    }];
}

#pragma mark - CaptureSessionManager delegate

- (void) CaptureSessionManagerDelegate_PhotoTaked:(UIImage*) photo
{
    lastPhoto = nil;
    photoResult = nil;
    if (!photo) {
        return;
    }
    
    lastPhoto = photo;
    
    [camManager stopRunning];
    [self showHideConfirm:YES];
    
    CoreMLManager *ml = [CoreMLManager new];
    [ml setupModelForPythonResult];
    
    [ml getCGRectTuplaPythonWithImage:lastPhoto
                       withCompletion:^(BOOL succes, CGRect rectResultTupla, NSError * _Nullable error)
     {
         NSLog(@"success: %@", succes?@"YES":@"NO");
         NSLog(@"error of getCGRectTuplaPythonWithImage: %@",error);
         if (succes)
         {
             NSLog(@"result CGRect: (%.0f, %.0f, %0.f, %.0f)", rectResultTupla.origin.x, rectResultTupla.origin.y, rectResultTupla.size.width, rectResultTupla.size.height);
             
             CGImageRef imageRef = CGImageCreateWithImageInRect([lastPhoto CGImage], rectResultTupla);
             
             photoResult = [UIImage imageWithCGImage:imageRef scale:lastPhoto.scale orientation:lastPhoto.imageOrientation];
             
             if (photoResult) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     self.imgPhotoTaken.image = photoResult;
                     self.imgPhotoTaken.hidden = NO;
                 });
             }
         }
     }];
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
