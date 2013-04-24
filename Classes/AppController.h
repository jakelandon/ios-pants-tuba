
#import "MyOpenAL.h"

//CLASS INTERFACES:

@interface AppController : NSObject <UIAccelerometerDelegate>
{
	BOOL tubaStopPlayed;
	
	UIWindow			*window;

	UIAccelerationValue	myAccelerometer[3];

	CFTimeInterval		lastTime;
}
@end
