//
//  MyOpenAL.h
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <AudioToolbox/AudioToolbox.h>

#define MARK	CMLog(@"%s", __PRETTY_FUNCTION__);
#define START_TIMER NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
#define END_TIMER(msg) 	NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate]; CMLog([NSString stringWithFormat:@"%@ Time = %f", msg, stop-start]);
#define CMLog(format, ...) NSLog(@"%s:%@", __PRETTY_FUNCTION__,[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define ALog CMLog(@"%s", __PRETTY_FUNCTION__);
@interface MyOpenAL : NSObject {
	
	ALCcontext* mContext; // stores the context (the 'air')
	ALCdevice* mDevice; // stores the device
	NSMutableArray * bufferStorageArray; // stores the buffer ids from openAL
	NSMutableDictionary * soundDictionary; // stores our soundkeys
}

// if you want to access directly the buffers or our sound dictionary
@property (nonatomic, retain) NSMutableArray * bufferStorageArray;
@property (nonatomic, retain) NSMutableDictionary * soundDictionary;

- (id) init; // init once
- (bool) initOpenAL; // no need to make it public, but I post it here to show you which methods we need. initOpenAL will be called within init process once.
- (void) playSoundWithKey:(NSString*)soundKey; // play a sound by name
- (void) stopSoundWithKey:(NSString*)soundKey; // stop a sound by name
- (bool) isPlayingSoundWithKey:(NSString *) soundKey; // check if sound is playing by name
- (void) rewindSoundWithKey:(NSString *) soundKey; // rewind a sound by name so its playing again
- (bool) loadSoundWithKey:(NSString *)_soundKey File:(NSString *)_file Ext:(NSString *) _ext Loop:(bool)loops; // load a sound and give it a name

+ (MyOpenAL*)sharedMyOpenAL; // access to our instance

@end