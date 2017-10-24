//
//  CoreMLManager.m
//  Stockfish
//
//  Created by Omar on 29/9/17.
//

#import "CoreMLManager.h"

#import "chess_pieces.h"
#import "chess_board_locate.h"

@implementation CoreMLManager
{
    CGFloat ratio;
}
#pragma mark - Initialize

+ (instancetype) initModelForType:(MLSetup) type
{
    CoreMLManager *ml = [CoreMLManager new];
    [ml setupModelForType:type];
    return ml;
}

- (void) setupModelForType:(MLSetup) type
{
    ratio = -1.0;
    [self closeAll];
    typeModel = type;
    if (type == MLSetupForPython)  {
        _model = [[[chess_board_locate alloc] init] model];
    }
    else if (type == MLSetupForChessPieces)  {
        _model = [[[chess_pieces alloc] init] model];
    }
    
    if (!_model) {
        self.isAvailable = NO;
        NSLog(@"Error in loading model.h");
        return;
    }
    
    _mlEngine = [VNCoreMLModel modelForMLModel: _model error:nil];
    
    self.isAvailable = YES;
    
    if (type == MLSetupForPython)
    {
        _mlRequest = [[VNCoreMLRequest alloc] initWithModel: _mlEngine completionHandler: (VNRequestCompletionHandler) ^(VNRequest *request, NSError *error)
                      {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              
                              long numberOfResults = request.results.count; //array the multiarrays
                              
                              if (numberOfResults > 0) {
                                  self.results = [request.results copy];
                                  VNCoreMLFeatureValueObservation *observations = (VNCoreMLFeatureValueObservation*) self.results[0];
                                  
                                  if (completionCGRect) {
                                      MLMultiArray *aux = observations.featureValue.multiArrayValue;
                                      
                                      [self testPythonSum:aux];
                                      
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
    else if (type == MLSetupForChessPieces)
    {
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
}

#pragma mark - Private methods
- (void) testPythonSum:(MLMultiArray*) multiArray
{
    NSInteger x = -1;
    NSInteger y = -1;
    NSInteger z = -1;
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = (width / 3 )* 4;
    UIView *viewPoints = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    BOOL exist = NO;
    
    if (multiArray.shape.count > 0) z = [multiArray.shape[0] integerValue];
    if (multiArray.shape.count > 1) x = [multiArray.shape[1] integerValue];
    if (multiArray.shape.count > 2) y = [multiArray.shape[2] integerValue];

    double maxValue = 0.90;
    double count = 0;
    double sum = 0;
    
    NSLog(@"(z,y,x) = value");
    for (int i = 0; i < x; i++)
    {
        for (int j = 0; j <y; j++)
        {
            for (int k = 0; k < 1; k++)
            {
                double evaluate = [[multiArray objectForKeyedSubscript:@[@(k), @(i), @(j)]] doubleValue];
                if (evaluate != evaluate) {
                    NSLog(@"evaluate value is a NAN");
                    return;
                }
                
                if (evaluate > maxValue) {
                    count++;
                    //NSLog(@"(%ld,%ld,%ld) = %f",(long)k, (long)j,(long)i, evaluate);
                    CGFloat posY = (j+1)*4;
                    CGFloat posX = (i+1)*4;
                    NSLog(@"point (%.0f, %.0f)", posX, posY);
                    [self drawPointInView:viewPoints forX:posX forY:posY];
                    exist = YES;
                }
                sum += evaluate;
            }
        }
    }
    NSLog(@"***********************************");
    NSLog(@"sum objc: %f   %f",sum, count);
    NSLog(@"***********************************");
    
    if (exist) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"points" object:viewPoints];
        });
        
    }
}

- (void) prepareRatio
{
    
    if (ratio < 0) {
        CGFloat maxSize = 480.0;
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        
        if (width > maxSize) {
            ratio = width / maxSize;
        }
        else if (width < maxSize) {
            
            ratio = maxSize / width;
        }
        else {
            ratio = 1.0;
        }
        /*
        
        if (width > maxSize) {
            ratio = maxSize / width;
        }
        else if (width < maxSize) {
            
            ratio = width / maxSize;
        }
        else {
            ratio = 1.0;
        }
         */
        
    }
}

- (void) drawPointInView:(UIView*) view forX:(CGFloat) x forY:(CGFloat)y
{
    if (ratio < 0) {
        [self prepareRatio];
    }
    
    UIColor *color = [UIColor redColor];
    CGFloat size = 3.0;
    
    CGFloat nPosX = x / ratio;
    CGFloat nPosY = y / ratio;
    
    CALayer *layer = [CALayer new];
    layer.frame = CGRectMake((nPosX-(size/2)),
                             (nPosY-(size/2)),
                             size, size);
    layer.backgroundColor = color.CGColor;
    [view.layer addSublayer:layer];
    
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
                double evaluate = [[multiArray objectForKeyedSubscript:@[@(k), @(j), @(i)]] doubleValue];
                if (evaluate > maxValue) {
                    indexZMaxValue = k;
                    maxValue = evaluate;
                }
            }
            NSDictionary *dic =  @{@"x": @(i), @"y": @(j), @"z": @(indexZMaxValue)};
            
            [arr addObject:dic];
            
            //NSLog(@"%d , %d -> %d", i, j, indexZMaxValue);
        }
    }
    
    return arr;
}

#pragma mark - Models Results

/*************************************************************************
 *
 *  GET MODELS RESULTS
 *
 *************************************************************************/

- (void) getChessPiecesWithImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionPieces _Nullable ) completion
{
    if (typeModel != MLSetupForChessPieces) {
        NSLog(@"***************************************");
        NSLog(@"**");
        NSLog(@"** setup does not match with the INIT model ");
        NSLog(@"**");
        NSLog(@"***************************************");
        exit(1);
    }
    
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
    if (typeModel != MLSetupForPython) {
        NSLog(@"***************************************");
        NSLog(@"**");
        NSLog(@"** setup does not match with the INIT model ");
        NSLog(@"**");
        NSLog(@"***************************************");
        exit(1);
    }
    
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

#pragma mark - Close Manager

- (void) closeAll
{
    _mlEngine = nil;
    _mlRequest = nil;
    _model = nil;
    self.delegate = nil;
    completionCGRect = nil;
    completionPieces = nil;
    self.isAvailable = NO;
}

- (void) dealloc
{
    [self closeAll];
    NSLog(@"dealloc CoreMLManager");
}

@end
