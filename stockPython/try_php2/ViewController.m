//
//  ViewController.m
//  try_php2
//
//  Created by Omar on 16/10/17.
//  Copyright © 2017 coneptum. All rights reserved.
//

#import "ViewController.h"

#include "../Python/dist/root/python/include/python2.7/Python.h"
//#include "/Users/toni/dev/kivy-ios/dist/include/common/sdl2/SDL_main.h"
//#include "_numpyconfig.h"#include <dlfcn.h>
//#include "test_numpy.h"
#include "ndarrayobject.h"
#include <dlfcn.h>

void export_orientation(void);
void load_custom_builtin_importer(void);

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self executePython:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    export_orientation();
    
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    NSLog(@"PythonHome is: %s", (char *)[resourcePath UTF8String]);
    Py_SetPythonHome((char *)[resourcePath UTF8String]);
    
    NSLog(@"Initializing python");
    Py_Initialize();
    // PySys_SetArgv(argc, argv);
    
    // If other modules are using the thread, we need to initialize them before.
    PyEval_InitThreads();
    
    // Add an importer for builtin modules
    load_custom_builtin_importer();
    NSString * path_stmt=[[@"import sys;sys.path.append('" stringByAppendingString:resourcePath] stringByAppendingString:@"/project_python')"];
    PyRun_SimpleString([path_stmt UTF8String]);
}
- (void) executePython:(NSArray*) multi
{
//    if (times == 0) {
        [self testInitOnce];
        
   // }
//    times ++;
//    NSLog(@"try");
    
    
    
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

void export_orientation() {
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

void load_custom_builtin_importer() {
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
