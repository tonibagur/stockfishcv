//
//  PythonManager.m
//  stockPython
//
//  Created by Omar on 17/10/17.
//  Copyright © 2017 coneptum. All rights reserved.
//

#import "PythonManager.h"

#include "../../../Python/dist/root/python/include/python2.7/Python.h"
#include "ndarrayobject.h"
#include <dlfcn.h>


void initExport_orientation(void);
void initLoad_custom_builtin_importer(void);

static PythonManager *sharedMyManager = nil;

@implementation PythonManager
{
    PyObject *pName;
    PyObject *pModule;
}

+ (id)sharedManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        [sharedMyManager initVariables];
    });
    return sharedMyManager;
}

- (void) initVariables
{
    [self initOncePython];
    [self loadModules];
}

- (void) loadModules
{
    pName = PyString_FromString("test_module");
    pModule = PyImport_Import(pName);
}


- (void) executePython:(MLMultiArray*) multi withCompletion:(PythonCompletionCGRectTupla) completion
{
    BOOL succes = NO;
    CGRect rect = CGRectZero;
    
    if (!multi) {
        NSLog(@" ********************** error MLMultiArray");
         [self completionFail:completion withError:nil];
        return;
    }
    
    PyObject *pFunc;
    PyObject *pArgs, *pValue;
    
    if (pModule == NULL) {
        [self loadModules];
    }
    
    if (pModule != NULL)
    {
        pFunc = PyObject_GetAttrString(pModule, "test_function");
        /* pFunc is a new reference */
        
        if (pFunc && PyCallable_Check(pFunc))
        {
            int numArgs=1;
            pArgs = PyTuple_New(numArgs);
            
            npy_intp shape[] = {[multi.shape[0] integerValue], [multi.shape[1] integerValue], [multi.shape[2] integerValue] };
            
            import_array()
            PyObject* arr=PyArray_SimpleNewFromData(2, shape, NPY_DOUBLE, multi.dataPointer);
            
            PyTuple_SetItem(pArgs, 0, arr);
            
            pValue = PyObject_CallObject(pFunc, pArgs);
            Py_DECREF(pArgs);
            if (pValue != NULL) {
                long x1,y1,x2,y2;
                if (PyTuple_Size(pValue) == 4)
                {
                    x1=PyInt_AsLong(PyTuple_GetItem(pValue, 0));
                    y1=PyInt_AsLong(PyTuple_GetItem(pValue, 1));
                    x2=PyInt_AsLong(PyTuple_GetItem(pValue, 2));
                    y2=PyInt_AsLong(PyTuple_GetItem(pValue, 3));
                    
                    if (y2 >= y1 && x2 >=x1 && (x1 != x2 || (y1 != y2))) {
                        rect = CGRectMake((float)x1, (float)y2, (float)x2-x1, (float) y2-y1);
                        succes = YES;
                    }
                    
                    printf("Result of call: %ld %ld %ld %ld\n", x1,y1,x2,y2);
                }
                else {
                    printf("Wrong params result of points");
                }
                Py_DECREF(pValue);
            }
            else {
                Py_DECREF(pFunc);
                PyErr_Print();
                fprintf(stderr,"Call failed\n");
                 [self completionFail:completion withError:nil];
                return ;
            }
        }
        else {
            if (PyErr_Occurred())
                PyErr_Print();
        }
        Py_XDECREF(pFunc);
    }
    else {
        PyErr_Print();
        [self completionFail:completion withError:nil];
        return ;
    }
    
    if (succes && completion) {
        completion(YES, rect, nil);
    }
    else {
        [self completionFail:completion withError:nil];
    }
}

- (void) completionFail:(PythonCompletionCGRectTupla) completion withError:(NSError*) error
{
    if (completion) {
        completion(NO, CGRectZero, error);
    }
}

- (void) dealloc
{
    [self releaseAll];
}

- (void) releaseAll
{
    Py_Finalize();
    Py_DECREF(pName);
    Py_DECREF(pModule);
}

#pragma mark - First Init

- (void) initOncePython
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
    initExport_orientation();
    
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    NSLog(@"PythonHome is: %s", (char *)[resourcePath UTF8String]);
    Py_SetPythonHome((char *)[resourcePath UTF8String]);
    
    NSLog(@"Initializing python");
    Py_Initialize();
    // PySys_SetArgv(argc, argv);
    
    // If other modules are using the thread, we need to initialize them before.
    PyEval_InitThreads();
    
    // Add an importer for builtin modules
    initLoad_custom_builtin_importer();
    NSString * path_stmt=[[@"import sys;sys.path.append('" stringByAppendingString:resourcePath] stringByAppendingString:@"/project_python')"];
    PyRun_SimpleString([path_stmt UTF8String]);
}

/**************************
 *
 *  First Init
 *
 ***************************/
void initExport_orientation() {
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

void initLoad_custom_builtin_importer() {
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
