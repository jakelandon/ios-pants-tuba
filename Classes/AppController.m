

#import "AppController.h"

//CONSTANTS:

#define kAccelerometerFrequency			25 //Hz
#define kFilteringFactor				0.1
#define kMinEraseInterval				2.22
#define kEraseAccelerationThreshold		0.3

//CLASS IMPLEMENTATIONS:

@implementation AppController

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	tubaStopPlayed = NO;
	
	srand(time(NULL));
	
	application.idleTimerDisabled = YES;
	
	//Create a full-screen window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	UIImage *image = [UIImage imageNamed:@"tuba.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	imageView.frame = CGRectMake(0, 0, 320, 480);
	[window addSubview:imageView];
	[window makeKeyAndVisible];
	

	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	
	//Load the sounds
	[[MyOpenAL sharedMyOpenAL] loadSoundWithKey:@"tuba_walk" File:@"tuba" Ext:@"aif" Loop:false];
	[[MyOpenAL sharedMyOpenAL] loadSoundWithKey:@"tuba_stop" File:@"tuba_fall" Ext:@"aif" Loop:false];
	
	//[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
}

-(void)onTimer
{
	//[ghostSound play];
}

- (void) dealloc
{
	//[selectSound release];
	//[walkingSound release];
	[window release];
	
	[super dealloc];
}




- (void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
	UIAccelerationValue				length,
									x,
									y,
									z;
	
	//Use a basic high-pass filter to remove the influence of the gravity
	myAccelerometer[0] = acceleration.x * kFilteringFactor + myAccelerometer[0] * (1.0 - kFilteringFactor);
	myAccelerometer[1] = acceleration.y * kFilteringFactor + myAccelerometer[1] * (1.0 - kFilteringFactor);
	myAccelerometer[2] = acceleration.z * kFilteringFactor + myAccelerometer[2] * (1.0 - kFilteringFactor);
	// Compute values for the three axes of the acceleromater
	x = acceleration.x - myAccelerometer[0];
	y = acceleration.y - myAccelerometer[1];
	z = acceleration.z - myAccelerometer[2];
	
	//Compute the intensity of the current acceleration 
	length = sqrt(x * x + y * y + z * z);

	

	if(length >= kEraseAccelerationThreshold)
	{
		if(CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval)
		{
			tubaStopPlayed = NO;
			[[MyOpenAL sharedMyOpenAL] stopSoundWithKey:@"tuba_stop"];
			[[MyOpenAL sharedMyOpenAL] playSoundWithKey:@"tuba_walk"];
		
			lastTime = CFAbsoluteTimeGetCurrent();
		
			if (random() % 10 == 0)
			{
				//[ghostSound play];
			}
		}
	}
	else
	{
		
	}
	
	NSLog( @"%f", length);
	
	if( length < .05 )
	{
		[[MyOpenAL sharedMyOpenAL] stopSoundWithKey:@"tuba_walk"];
		
		if( !tubaStopPlayed )
		{
			[[MyOpenAL sharedMyOpenAL] playSoundWithKey:@"tuba_stop"];
			
			tubaStopPlayed = YES;
		}
	}
}

@end
