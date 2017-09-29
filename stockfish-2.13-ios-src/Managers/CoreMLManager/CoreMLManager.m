//
//  CoreMLManager.m
//  Stockfish
//
//  Created by Omar on 29/9/17.
//

#import "CoreMLManager.h"

#import "chess500.h"


@implementation CoreMLManager
{
    BOOL isAvailable;
}

- (void) setupModel
{
    MLModel *model = [[[chess500 alloc] init] model];
    if (!model) {
        isAvailable = NO;
        NSLog(@"Error in loading model.h");
        return;
    }
    
    _mlEngine = [VNCoreMLModel modelForMLModel: model error:nil];
    if (!_mlEngine) {
        isAvailable = NO;
        NSLog(@"Error in model");
        return;
    }
    isAvailable = YES;
    
    _mlRequest = [[VNCoreMLRequest alloc] initWithModel: _mlEngine completionHandler: (VNRequestCompletionHandler) ^(VNRequest *request, NSError *error)
                  {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          
                          long numberOfResults = request.results.count; //array the multiarrays
                          
                          if (numberOfResults > 0) {
                              self.results = [request.results copy];
                              VNCoreMLFeatureValueObservation *observations = (VNCoreMLFeatureValueObservation*) self.results[0];
                              
                              NSLog(@"%@", observations.featureValue.multiArrayValue[0]);
                              
                              
                              if (completionHandler) {
                                  completionHandler(YES, nil);
                              }
                          }                          
                      });
                  }];
}


- (void) executeImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionHandler _Nullable ) completion
{
    if (!isAvailable) {
        NSLog(@"CoreML not available, is not initialize");
        return;
    }
    self.results = @[];
    
    NSArray *a = @[_mlRequest];
    
    if (!image) {
        image = [UIImage imageNamed:@"tablero2"];
    }
    
    completionHandler = completion;

    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];
    dispatch_async(dispatch_get_main_queue(), ^{
        [handler performRequests:a error:nil];
    });
}


@end
