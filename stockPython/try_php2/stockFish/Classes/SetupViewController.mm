/*
 Stockfish, a chess program for iOS.
 Copyright (C) 2004-2014 Tord Romstad, Marco Costalba, Joona Kiiski
 
 Stockfish is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Stockfish is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "BoardViewController.h"
#import "Options.h"
#import "SelectedPieceView.h"
#import "SetupBoardView.h"
#import "SetupViewController.h"
#import "SideToMoveController.h"

//#import "CoreMLManager.h"

#include "../../../Python/dist/root/python/include/python2.7/Python.h"
//#include "/Users/toni/dev/kivy-ios/dist/include/common/sdl2/SDL_main.h"
//#include "_numpyconfig.h"#include <dlfcn.h>
//#include "test_numpy.h"
#include "ndarrayobject.h"
#include <dlfcn.h>

void bexport_orientation(void);
void bload_custom_builtin_importer(void);

@implementation SetupViewController 
{
    CameraVC *camVC;
    int times;
}

@synthesize boardViewController;

- (id)initWithBoardViewController:(BoardViewController *)bvc
                              fen:(NSString *)aFen {
    if (self = [super init]) {
        [self setTitle: @"Board"];
        boardViewController = bvc;
        fen = aFen;
        [self setPreferredContentSize: CGSizeMake(320.0f, 418.0f)];
    }
    return self;
}


- (void) addButtonToCam
{
    CGRect r = [UIScreen mainScreen].bounds;
    UIButton *btCustomCam  = [UIButton buttonWithType:UIButtonTypeSystem];
    btCustomCam.tintColor = [UIColor redColor];
    btCustomCam.frame = CGRectMake(0, 0, 180, 50);
    btCustomCam.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    [btCustomCam setTitle:@"Camera Photo" forState:UIControlStateNormal];
    btCustomCam.center = CGPointMake(r.size.width/2, r.size.height-40);
    [btCustomCam addTarget:self action:@selector(btnPressOnCam) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btCustomCam];
}

- (void)loadView {
    UIView *contentView;
    times = 0;
    CGRect r = [[UIScreen mainScreen] applicationFrame];
    contentView = [[UIView alloc] initWithFrame: r];
    [self setView: contentView];
    [contentView setBackgroundColor: [UIColor colorWithRed: 0.934 green: 0.934 blue: 0.953 alpha: 1.0]];
    
    // Create a UISegmentedControl as a menu at the top of the screen
    NSArray *buttonNames = @[@"Clear", @"Cancel", @"Done"];
    menu = [[UISegmentedControl alloc] initWithItems: buttonNames];
    [menu setMomentary: YES];
    //[menu setSegmentedControlStyle: UISegmentedControlStyleBar];
    [menu setFrame: CGRectMake(0.0f, 0.0f, 300.0f, 20.0f)];
    [menu addTarget: self
             action: @selector(buttonPressed:)
   forControlEvents: UIControlEventValueChanged];
    [[self navigationItem] setTitleView: menu];
    
    [self addButtonToCam];
    BOOL isIpad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    
    // Selected piece view
    SelectedPieceView *spv;
    
    // I have no idea why, but the vertical view coordinates are different in
    // iOS 7 and iOS 8. We need to compensate for this to be able to handle both
    // OS versions correctly.
    BOOL isRunningiOS7 = [UIDevice currentDevice].systemVersion.floatValue < 8.0f;
    float sqSize;
    float dy = isIpad ? 50.0f : 64.0f;
    if (isIpad && isRunningiOS7) dy -= 34.0f;
    
    if (isIpad) {
        sqSize = 40.0f;
        spv = [[SelectedPieceView alloc] initWithFrame:CGRectMake(40.0f, 320.0f + dy, 240.0f, 80.0f)];
    } else {
        sqSize = [UIScreen mainScreen].applicationFrame.size.width / 8.0f;
        spv = [[SelectedPieceView alloc]
               initWithFrame:CGRectMake(40.0f, 8*sqSize + 74.0f, 6*sqSize, 2*sqSize)];
    }
    [contentView addSubview: spv];
    
    // Setup board view
    dy = isIpad ? 40.0f : 64.0f;
    if (isIpad && isRunningiOS7) dy -= 34.0f;
    boardView = [[SetupBoardView alloc]
                 initWithController: self
                 frame: CGRectMake(0.0f, dy, 8*sqSize, 8*sqSize)
                 fen: fen
                 phase: PHASE_EDIT_BOARD];
    [contentView addSubview: boardView];
    [boardView setSelectedPieceView: spv];
    
}

- (void) btnPressOnCam
{
    
    [self executePython:nil];
    return;
    
    
#if TARGET_IPHONE_SIMULATOR
    [self openTheML:nil];
    return;
#endif
    
    [self openCamera];
}

- (void) openCamera
{
    if (!camVC) {
        camVC = [CameraVC new];
        camVC.delegate = self;
    }
    
    [self presentViewController:camVC animated:YES completion:nil];
}

- (void) openTheML:(UIImage*) image
{
    /*
    NSLog(@"openML");
    
//    if (camVC) {
//        camVC.delegate = self;
//        camVC = nil;
//    }
    
    [boardView clear];
    
    CoreMLManager *ml = [[CoreMLManager alloc]init];
    [ml setupModel];
    
    UIImage *smallImage = image?[Utils onlyScaleImage:image toMaxResolution:400]:nil;
    
    [ml executeImage:smallImage withCompletion:^(BOOL succes, NSMutableArray * _Nullable arrResultPieces, NSError * _Nullable error)
     {
         NSLog(@"success: %@", succes?@"YES":@"NO");
         NSLog(@"error of completion: %@",error);
       //  NSLog(@"arrResults: %@", arrResultPieces);
         
         dispatch_async(dispatch_get_main_queue(), ^{
             
             for (NSDictionary *dic in arrResultPieces)
             {
                 
                 NSInteger x = [dic[@"x"]integerValue];
                 NSInteger y = [dic[@"y"]integerValue];
                 Piece piece = [boardView pieceFromMLByCode:[dic[@"z"]integerValue]];
                 
                 if (piece == NO_PIECE) {
                     [boardView removePieceOnSquare:make_square(File(y), Rank(7-x))];
                 }
                 else {
                     [boardView addPiece:[boardView pieceFromMLByCode:[dic[@"z"]integerValue]] onSquare:make_square(File(y), Rank(7-x))];
                 }
             }
             
             [ml closeAll];
             [self enableDoneButton];

         });
     }];
    */
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)buttonPressed:(id)sender {
    switch([sender selectedSegmentIndex]) {
        case 0:
            [boardView clear];
            break;
        case 1:
            [boardViewController editPositionCancelPressed];
            break;
        case 2:
            SideToMoveController *stmc = [[SideToMoveController alloc]
                                          initWithFen: [boardView fen]];
            [[self navigationController] pushViewController: stmc animated: YES];
            break;
    }
}


- (void)disableDoneButton {
    [menu setEnabled: NO forSegmentAtIndex: 2];
}


- (void)enableDoneButton {
    [menu setEnabled: YES forSegmentAtIndex: 2];
}

#pragma mark - CameraVC Delegate
- (void) cameraDidSelectPhoto:(UIImage *)imageSelected
{
    NSLog(@"did select photo from camera");
    NSLog(@"%@", imageSelected);
    [self openTheML:imageSelected];
}


#pragma mark - PYTHON

- (void) testInitOnce
{
    // Change the executing path to YourApp
    chdir("project_python");
    
    // Special environment to prefer .pyo, and don't write bytecode if .py are found
    // because the process will not have a write attribute on the device.
    putenv("PYTHONOPTIMIZE=2");
    putenv("PYTHONDONTWRITEBYTECODE=1");
    putenv("PYTHONNOUSERSITE=1");
    putenv("PYTHONPATH=.");
    //putenv("PYTHONVERBOSE=1");
    
    // Kivy environment to prefer some implementation on iOS platform
    putenv("KIVY_BUILD=ios");
    putenv("KIVY_NO_CONFIG=1");
    putenv("KIVY_NO_FILELOG=1");
    putenv("KIVY_WINDOW=sdl2");
    putenv("KIVY_IMAGE=imageio,tex");
    putenv("KIVY_AUDIO=sdl2");
    putenv("KIVY_GL_BACKEND=sdl2");
#ifndef DEBUG
    putenv("KIVY_NO_CONSOLELOG=1");
#endif
    
    // Export orientation preferences for Kivy
    bexport_orientation();
    
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    NSLog(@"PythonHome is: %s", (char *)[resourcePath UTF8String]);
    Py_SetPythonHome((char *)[resourcePath UTF8String]);
    
    NSLog(@"Initializing python");
    Py_Initialize();
    // PySys_SetArgv(argc, argv);
    
    // If other modules are using the thread, we need to initialize them before.
    PyEval_InitThreads();
    
    // Add an importer for builtin modules
    bload_custom_builtin_importer();
    NSString * path_stmt=[[@"import sys;sys.path.append('" stringByAppendingString:resourcePath] stringByAppendingString:@"/project_python'); import numpy as np"];
    PyRun_SimpleString([path_stmt UTF8String]);
}
- (void) executePython:(NSArray*) multi
{
//    if (times == 0) {
        [self testInitOnce];
//
//    }
        times ++;
        NSLog(@"try");
    
    
    
    PyObject *pName, *pModule, *pDict, *pFunc;
    PyObject *pArgs, *pValue;
    int i;
    
    pName = PyString_FromString("test_module");
    pModule = PyImport_Import(pName);
    Py_DECREF(pName);
    
    if (pModule != NULL) {
        pFunc = PyObject_GetAttrString(pModule, "test_function");
        /* pFunc is a new reference */
        
        if (pFunc && PyCallable_Check(pFunc)) {
            int numArgs=1;
            pArgs = PyTuple_New(numArgs);
            printf("Testing numpy\n");
            if (multi) {
                
            }
            double array[]={1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0};
            npy_intp shape[]={3,3};
            import_array()
            PyObject* arr=PyArray_SimpleNewFromData(2, shape, NPY_DOUBLE, array);
            
            PyTuple_SetItem(pArgs, 0, arr);
            
            pValue = PyObject_CallObject(pFunc, pArgs);
            Py_DECREF(pArgs);
            if (pValue != NULL) {
                printf("Result of call: %ld\n", PyInt_AsLong(pValue));
                Py_DECREF(pValue);
            }
            else {
                Py_DECREF(pFunc);
                Py_DECREF(pModule);
                PyErr_Print();
                fprintf(stderr,"Call failed\n");
                return ;
            }
        }
        else {
            if (PyErr_Occurred())
                PyErr_Print();
            // fprintf(stderr, "Cannot find function \"%s\"\n", argv[2]);
        }
        Py_XDECREF(pFunc);
        Py_DECREF(pModule);
    }
    else {
        PyErr_Print();
        // fprintf(stderr, "Failed to load \"%s\"\n", argv[1]);
        return ;
    }
    
    // Py_Finalize();
    
    
}

void bexport_orientation() {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSArray *orientations = [info objectForKey:@"UISupportedInterfaceOrientations"];
    
    // Orientation restrictions
    // ========================
    // Comment or uncomment blocks 1-3 in order the limit orientation support
    
    // 1. Landscape only
    // NSString *result = [[NSString alloc] initWithString:@"KIVY_ORIENTATION=LandscapeLeft LandscapeRight"];
    
    // 2. Portrait only
    // NSString *result = [[NSString alloc] initWithString:@"KIVY_ORIENTATION=Portrait PortraitUpsideDown"];
    
    // 3. All orientations
    NSString *result = [[NSString alloc] initWithString:@"KIVY_ORIENTATION="];
    for (int i = 0; i < [orientations count]; i++) {
        NSString *item = [orientations objectAtIndex:i];
        item = [item substringFromIndex:22];
        if (i > 0)
            result = [result stringByAppendingString:@" "];
        result = [result stringByAppendingString:item];
    }
    // ========================
    
    putenv((char *)[result UTF8String]);
    NSLog(@"Available orientation: %@", result);
}

void bload_custom_builtin_importer() {
    static const char *custom_builtin_importer = \
    "import sys, imp\n" \
    "from os import environ\n" \
    "from os.path import exists, join\n" \
    "# Fake redirection to supress console output\n" \
    "if environ.get('KIVY_NO_CONSOLE', '0') == '1':\n" \
    "    class fakestd(object):\n" \
    "        def write(self, *args, **kw): pass\n" \
    "        def flush(self, *args, **kw): pass\n" \
    "    sys.stdout = fakestd()\n" \
    "    sys.stderr = fakestd()\n" \
    "# Custom builtin importer for precompiled modules\n" \
    "class CustomBuiltinImporter(object):\n" \
    "    def find_module(self, fullname, mpath=None):\n" \
    "        print 'finding module '+fullname\n"\
    "        if '.' not in fullname:\n" \
    "            return\n" \
    "        if not mpath:\n" \
    "            return\n" \
    "        part = fullname.rsplit('.')[-1]\n" \
    "        fn = join(mpath[0], '{}.so'.format(part))\n" \
    "        if exists(fn):\n" \
    "            return self\n" \
    "        return\n" \
    "    def load_module(self, fullname):\n" \
    "        print 'loading module '+fullname\n"\
    "        f = fullname.replace('.', '_')\n" \
    "        mod = sys.modules.get(f)\n" \
    "        if mod is None:\n" \
    "            # print 'LOAD DYNAMIC', f, sys.modules.keys()\n" \
    "            try:\n" \
    "                mod = imp.load_dynamic(f, f)\n" \
    "            except ImportError:\n" \
    "                # import traceback; traceback.print_exc();\n" \
    "                # print 'LOAD DYNAMIC FALLBACK', fullname\n" \
    "                mod = imp.load_dynamic(fullname, fullname)\n" \
    "            sys.modules[fullname] = mod\n" \
    "            return mod\n" \
    "        return mod\n" \
    "sys.meta_path.append(CustomBuiltinImporter())";
    PyRun_SimpleString(custom_builtin_importer);
}


@end
