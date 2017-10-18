//
//  CoreMLManager.m
//  Stockfish
//
//  Created by Omar on 29/9/17.
//

#import "CoreMLManager.h"

#import "chess_pieces.h"

@implementation CoreMLManager

- (void) closeAll
{
    _mlEngine = nil;
    _mlRequest = nil;
    _modelPieces = nil;
    self.delegate = nil;
    completionCGRect = nil;
    completionPieces = nil;
    self.isAvailable = NO;
}


- (void) setupModelForPythonResult
{
    _modelPieces = [[[chess_pieces alloc] init] model];
    
    if (!_modelPieces) {
        self.isAvailable = NO;
        NSLog(@"Error in loading model.h");
        return;
    }
    
    _mlEngine = [VNCoreMLModel modelForMLModel: _modelPieces error:nil];
    if (!_mlEngine) {
        self.isAvailable = NO;
        NSLog(@"Error in model to GET POINTS for Python");
        return;
    }
    self.isAvailable = YES;
    
    _mlRequest = [[VNCoreMLRequest alloc] initWithModel: _mlEngine completionHandler: (VNRequestCompletionHandler) ^(VNRequest *request, NSError *error)
                  {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          
                          long numberOfResults = request.results.count; //array the multiarrays
                          
                          if (numberOfResults > 0) {
                              self.results = [request.results copy];
                              VNCoreMLFeatureValueObservation *observations = (VNCoreMLFeatureValueObservation*) self.results[0];

                              if (completionCGRect) {
                                  MLMultiArray *aux = observations.featureValue.multiArrayValue;
                                  
                                  if (!python) {
                                      python = [PythonManager sharedManager];
                                  }
                                  
                                  [python executePython:aux withCompletion:^(BOOL succes, CGRect rectResultTupla, NSError * _Nullable error)
                                  {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                               completionCGRect(succes, rectResultTupla, error);
                                       });
                                  }];
                              }
                          }
                          else if (completionCGRect) {
                              completionCGRect(NO, CGRectZero, [NSError errorWithDomain:@"" code:999 userInfo:@{@"message":@"insuficients results in results request"}]);
                              
                          }
                      });
                  }];
}

- (void) setupModelForPieces
{
    _modelPieces = [[[chess_pieces alloc] init] model];
    
    if (!_modelPieces) {
        self.isAvailable = NO;
        NSLog(@"Error in loading model.h");
        return;
    }
    
    _mlEngine = [VNCoreMLModel modelForMLModel: _modelPieces error:nil];
    if (!_mlEngine) {
        self.isAvailable = NO;
        NSLog(@"Error in model for DETECT PIECES CHESS");
        return;
    }
    self.isAvailable = YES;
    
    _mlRequest = [[VNCoreMLRequest alloc] initWithModel: _mlEngine completionHandler: (VNRequestCompletionHandler) ^(VNRequest *request, NSError *error)
                  {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          
                          long numberOfResults = request.results.count; //array the multiarrays
                          
                          if (numberOfResults > 0) {
                              self.results = [request.results copy];
                              VNCoreMLFeatureValueObservation *observations = (VNCoreMLFeatureValueObservation*) self.results[0];
                              
                              NSMutableArray *arr = [self evaluateMultiArray:observations.featureValue.multiArrayValue];
                              
                              if (completionPieces) {
                                  completionPieces((arr && arr.count > 0)?YES:NO, arr, nil);
                              }
                          }
                          else if (completionPieces) {
                              completionPieces(NO, nil, [NSError errorWithDomain:@"" code:999 userInfo:@{@"message":@"insuficients results in results request"}]);
                              
                          }
                      });
                  }];
}

- (NSMutableArray*) evaluateMultiArray:(MLMultiArray*) multiArray
{
    // evaluate pieces of tablero
    NSInteger x = -1;
    NSInteger y = -1;
    NSInteger z = -1;
    
    if (multiArray.shape.count > 0) z = [multiArray.shape[0] integerValue]; // 13
    if (multiArray.shape.count > 1) y = [multiArray.shape[1] integerValue]; //  8
    if (multiArray.shape.count > 2) x = [multiArray.shape[2] integerValue]; //  8
    
    NSMutableArray *arr = [NSMutableArray new];
    
    for (int i = 0; i < x; i++)
    {
        for (int j = 0; j <y; j++)
        {
            double maxValue = -1;
            int indexZMaxValue = -1;
            
            for (int k = 0; k < z; k++)
            {
                double evaluate = [[multiArray objectForKeyedSubscript:@[@(k), @(i), @(j)]] doubleValue];
                if (evaluate > maxValue) {
                    indexZMaxValue = k;
                    maxValue = evaluate;
                }
            }
            NSDictionary *dic =  @{@"x": @(i), @"y": @(j), @"z": @(indexZMaxValue)};
            
            [arr addObject:dic];
            
            NSLog(@"%d , %d -> %d", i, j, indexZMaxValue);
        }
    }
    
    return arr;
}

- (void) getChessPiecesWithImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionPieces _Nullable ) completion
{
    if (!self.isAvailable) {
        NSLog(@"CoreML not available, is not initialize");
        if (completion) {
            completion(NO, nil, [NSError errorWithDomain:@"" code:1 userInfo:@{@"message":@"unavailable ml initialize"}]);
            
        }
        return;
    }
    self.results = @[];
    
    NSArray *a = @[_mlRequest];
    
    if (!image) {
        image = [UIImage imageNamed:@"tablero"];
    }
    
    completionPieces = completion;
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];
    dispatch_async(dispatch_get_main_queue(), ^{
        [handler performRequests:a error:nil];
    });
}


- (void) getCGRectTuplaPythonWithImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionCGRectTupla _Nullable ) completion
{
    if (!self.isAvailable) {
        NSLog(@"CoreML not available, is not initialize");
         if (completion) {
            completion(NO, CGRectZero, [NSError errorWithDomain:@"" code:1 userInfo:@{@"message":@"unavailable ml initialize"}]);
            
        }
        return;
    }
    self.results = @[];
    
    NSArray *a = @[_mlRequest];
    
    if (!image) {
        image = [UIImage imageNamed:@"tablero"];
    }
    completionCGRect = completion;
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];
    dispatch_async(dispatch_get_main_queue(), ^{
        [handler performRequests:a error:nil];
    });
}

- (void) dealloc
{
    [self closeAll];
    NSLog(@"dealloc CoreMLManager");
}

@end
