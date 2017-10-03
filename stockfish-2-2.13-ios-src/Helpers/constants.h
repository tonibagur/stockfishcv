//
//  constants.h
//  Stockfish
//
//  Created by Omar on 3/10/17.
//

#ifndef constants_h
#define constants_h


#define needsFullLOGS true

#define kMainQueue dispatch_get_main_queue()

static dispatch_queue_t my_queue_download() {
    static dispatch_queue_t s_serial_queue;
    static dispatch_once_t s_done;
    dispatch_once(&s_done, ^{s_serial_queue = dispatch_queue_create("test.coneptum.queue.download", NULL);});
    return s_serial_queue;
}

#define kQueueBgDownload my_queue_download()

#if TARGET_OS_SIMULATOR || needsFullLOGS == true
    #define LogInfoDetail(fmt, ...) NSLog( ( fmt @"\n      --> %s [Line %d]" ), ##__VA_ARGS__, __PRETTY_FUNCTION__, __LINE__);
    #define LogInfo(fmt, ...) NSLog( ( @" --> " fmt), ##__VA_ARGS__);
#else
    #define LogInfo(fmt, ...) //NSLog( ( @"" ));
    #define LogInfoDetail(fmt, ...) //NSLog( ( @"" ));
#endif

#import "Utils.h"

#endif /* constants_h */
