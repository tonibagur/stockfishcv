//
//  PythonManager.h
//  stockPython
//
//  Created by Omar on 17/10/17.
//  Copyright © 2017 coneptum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>

@interface PythonManager : NSObject

+ (id)sharedManager;

- (void) executePython:(MLMultiArray*) multi;
@end
