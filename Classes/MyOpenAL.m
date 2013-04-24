//
//  MyOpenAL.m
//

#import "MyOpenAL.h"
#import "MyOpenALSupport.h"

@implementation MyOpenAL

@synthesize bufferStorageArray;
@synthesize soundDictionary;

static MyOpenAL *sharedMyOpenAL = nil;

- (void) shutdownMyOpenAL {
	@synchronized(self) {
        if (sharedMyOpenAL != nil) {
			[self dealloc]; // assignment not done here
        }
    }
}

+ (MyOpenAL*)sharedMyOpenAL {
	
    @synchronized(self) {
        if (sharedMyOpenAL == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedMyOpenAL;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedMyOpenAL == nil) {
            sharedMyOpenAL = [super allocWithZone:zone];
            return sharedMyOpenAL;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (unsigned)retainCount
{
	
	return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

// seek in audio file for the property 'size'
// return the size in bytes
-(UInt32)audioFileSize:(AudioFileID)fileDescriptor
{
	MARK;
	UInt64 outDataSize = 0;
	UInt32 thePropSize = sizeof(UInt64);
	OSStatus result = AudioFileGetProperty(fileDescriptor, kAudioFilePropertyAudioDataByteCount, &thePropSize, &outDataSize);
	if(result != 0) NSLog(@"cannot find file size");
	return (UInt32)outDataSize;
}

// start up openAL
-(bool) initOpenAL
{
	MARK;
	// Initialization
	mDevice = alcOpenDevice(NULL); // select the "preferred device"
	if (mDevice) {
		// use the device to make a context
		mContext=alcCreateContext(mDevice,NULL);
		// set my context to the currently active one
		alcMakeContextCurrent(mContext);
		return true;
	}
	return false;
}

-(id) init {
	MARK;
	if (self = [super init] ) {
		if ([self initOpenAL]) {
			self.bufferStorageArray = [[[NSMutableArray alloc]init]autorelease];
			self.soundDictionary = [[[NSMutableDictionary alloc]init]autorelease];
			
		}
		return self;
	}
	[self release];
	return nil;
}

-(void) dealloc {
	
	MARK;
	// delete the sources
	for (NSNumber * sourceNumber in [soundDictionary allValues]) {
		NSUInteger sourceID = [sourceNumber unsignedIntegerValue];
		alDeleteSources(1, &sourceID);
	}
	
	self.soundDictionary=nil;
	
	// delete the buffers
	for (NSNumber * bufferNumber in bufferStorageArray) {
		NSUInteger bufferID = [bufferNumber unsignedIntegerValue];
		alDeleteBuffers(1, &bufferID);
	}
	self.bufferStorageArray=nil;
	
	// destroy the context
	alcDestroyContext(mContext);
	// close the device
	alcCloseDevice(mDevice);
	
	[super dealloc];
}

// the main method: grab the sound ID from the library
// and start the source playing
- (void)playSoundWithKey:(NSString*)soundKey
{
	MARK;
	NSNumber * numVal = [soundDictionary objectForKey:soundKey];
	if (numVal == nil) return;
	NSUInteger sourceID = [numVal unsignedIntValue];
	alSourcePlay(sourceID);
}

- (void)stopSoundWithKey:(NSString*)soundKey
{
	MARK;
	NSNumber * numVal = [soundDictionary objectForKey:soundKey];
	if (numVal == nil) return;
	NSUInteger sourceID = [numVal unsignedIntValue];
	alSourceStop(sourceID);
}

-(void) rewindSoundWithKey:(NSString *) soundKey {
	
	MARK;
	NSNumber * numVal = [soundDictionary objectForKey:soundKey];
	if (numVal == nil) return;
	NSUInteger sourceID = [numVal unsignedIntValue];
	alSourceRewind (sourceID);
}

-(bool) isPlayingSoundWithKey:(NSString *) soundKey {
	
	MARK;
	NSNumber * numVal = [soundDictionary objectForKey:soundKey];
	if (numVal == nil) return false;
	NSUInteger sourceID = [numVal unsignedIntValue];
	
	ALenum state;
	
    alGetSourcei(sourceID, AL_SOURCE_STATE, &state);
	
    return (state == AL_PLAYING);
}

-(bool) loadSoundWithKey:(NSString *)_soundKey File:(NSString *)_file Ext:(NSString *) _ext Loop:(bool)loops{
	
	START_TIMER;
	
	ALvoid * outData;
	ALenum  error = AL_NO_ERROR;
	ALenum  format;
	ALsizei size;
	ALsizei freq;
	
	NSBundle * bundle = [NSBundle mainBundle];
	
	// get some audio data from a wave file
	CFURLRef fileURL = (CFURLRef)[[NSURL fileURLWithPath:[bundle pathForResource:_file ofType:_ext]] retain];
	
	if (!fileURL)
	{
		END_TIMER(@"file not found.");
		return false;
	}
	
	outData = MyGetOpenALAudioData(fileURL, &size, &format, &freq);
	
	CFRelease(fileURL);
	
	if((error = alGetError()) != AL_NO_ERROR) {
		printf("error loading sound: %x\n", error);
		exit(1);
	}
	
	ALog(@"getting a free buffer from openAL.");
	NSUInteger bufferID;
	// grab a buffer ID from openAL
	alGenBuffers(1, &bufferID);
	
	ALog(@"loading audio data into openAL buffer.");
	// load the awaiting data blob into the openAL buffer.
	alBufferData(bufferID,format,outData,size,freq); 
	
	// save the buffer so we can release it later
	[bufferStorageArray addObject:[NSNumber numberWithUnsignedInteger:bufferID]];
	
	ALog(@"getting a free source from openAL.");
	NSUInteger sourceID;
	// grab a source ID from openAL
	alGenSources(1, &sourceID); 
	
	ALog(@"attatching the buffer to the source and setting up preferences");
	// attach the buffer to the source
	alSourcei(sourceID, AL_BUFFER, bufferID);
	// set some basic source prefs
	alSourcef(sourceID, AL_PITCH, 1.0f);
	alSourcef(sourceID, AL_GAIN, 1.0f);
	if (loops) alSourcei(sourceID, AL_LOOPING, AL_TRUE);
	
	// store this for future use
	[soundDictionary setObject:[NSNumber numberWithUnsignedInt:sourceID] forKey:_soundKey];	
	
	ALog(@"free %i bytes of temporary allocated memory.", size);
	// clean up the buffer
	if (outData)
	{
		free(outData);
		outData = NULL;
	}
	
	END_TIMER(@"Audiofile successfully loaded.");
	return true;
	
}
@end