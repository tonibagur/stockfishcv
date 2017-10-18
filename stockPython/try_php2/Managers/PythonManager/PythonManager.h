//
//  PythonManager.h
//  stockPython
//
//  Created by Omar on 17/10/17.
//  Copyright © 2017 coneptum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>

typedef void (^PythonCompletionCGRectTupla)(BOOL succes, CGRect rectResultTupla, NSError * _Nullable error);

@interface PythonManager : NSObject

+ (id _Nullable )sharedManager;

- (void) executePython:(MLMultiArray* _Nullable) multi withCompletion:(PythonCompletionCGRectTupla _Nullable) completion;

@end
