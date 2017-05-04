//
//  MMLocationManager.m
//  DemoBackgroundLocationUpdate
//
//  Created by Ralph Li on 7/20/15.
//  Copyright (c) 2015 LJC. All rights reserved.
//

#import "MMLocationManager.h"

//#import <Realm/Realm.h>
//#import "MMLoc.h"

@interface MMLocationManager()
<
CLLocationManagerDelegate
>

//@property (nonatomic, assign) UIBackgroundTaskIdentifier taskIdentifier;

@end

NSMutableArray *locationMutableArray;
CGFloat last_latitude;
CGFloat last_longitude;


@implementation MMLocationManager

+ (instancetype)sharedManager
{
    static MMLocationManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MMLocationManager alloc] init];
    });
    
    return instance;
}

+ (NSMutableArray *) getlocationMutableArray
{
    return locationMutableArray;
    
}

+ (CGFloat) getlastlatitude{ return last_latitude;   }
+ (CGFloat) getlastlongitude{ return last_longitude;   }

- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        self.minSpeed = 3;
        self.minFilter = 50;
        self.minInteval = 10;
        
        self.delegate = self;
        self.distanceFilter  = self.minFilter;
        self.desiredAccuracy = kCLLocationAccuracyBest;
        
        //创建存放位置的数组
         locationMutableArray = [[NSMutableArray alloc] init];
        
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = locations[0];
    
    NSLog(@"%@",location);
    NSLog(@"添加进位置数组");
    
    last_latitude = location.coordinate.latitude;
    last_longitude = location.coordinate.longitude;
    
    NSString *locationString = [NSString stringWithFormat:@"%f,%f",location.coordinate.latitude, location.coordinate.longitude];
   [ locationMutableArray addObject:locationString];

       
    
    [self adjustDistanceFilter:location];
    [self uploadLocation:location];
}

/**
 *  规则: 如果速度小于minSpeed m/s 则把触发范围设定为50m
 *  否则将触发范围设定为minSpeed*minInteval
 *  此时若速度变化超过10% 则更新当前的触发范围(这里限制是因为不能不停的设置distanceFilter,
 *  否则uploadLocation会不停被触发)
 */
- (void)adjustDistanceFilter:(CLLocation*)location
{
//    NSLog(@"adjust:%f",location.speed);
    
    if ( location.speed < self.minSpeed )
    {
        if ( fabs(self.distanceFilter-self.minFilter) > 0.1f )
        {
            self.distanceFilter = self.minFilter;
        }
    }
    else
    {
        CGFloat lastSpeed = self.distanceFilter/self.minInteval;
        
        if ( (fabs(lastSpeed-location.speed)/lastSpeed > 0.1f) || (lastSpeed < 0) )
        {
            CGFloat newSpeed  = (int)(location.speed+0.5f);
            CGFloat newFilter = newSpeed*self.minInteval;
            
            self.distanceFilter = newFilter;
        }
    }
}


//这里仅用本地数据库模拟上传操作
- (void)uploadLocation:(CLLocation*)location
{
    NSLog(@"uploadLocation");
    
    /*
    MMLoc *loc = [MMLoc new];
    loc.date       = [NSDate date];
    loc.background = ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground);
    loc.loc        = [NSString stringWithFormat:@"speed:%.0f filter:%.0f",location.speed,self.distanceFilter];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm transactionWithBlock:^{
        [realm addObject:loc];
        
    }];
    */
    
#warning 如果有较长时间的操作 比如HTTP上传 请使用beginBackgroundTaskWithExpirationHandler
//    if ( [UIApplication sharedApplication].applicationState == UIApplicationStateActive )
//    {
//        //TODO HTTP upload
//        
//        [self endBackgroundUpdateTask];
//    }
//    else//后台定位
//    {
//        //假如上一次的上传操作尚未结束 则直接return
//        if ( self.taskIdentifier != UIBackgroundTaskInvalid )
//        {
//            return;
//        }
//        
//        [self beingBackgroundUpdateTask];
//        
//        //TODO HTTP upload
//        //上传完成记得调用 [self endBackgroundUpdateTask];
//    }
    
}


//- (void)beingBackgroundUpdateTask
//{
//    self.taskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
//        [self endBackgroundUpdateTask];
//    }];
//}
//
//- (void)endBackgroundUpdateTask
//{
//    if ( self.taskIdentifier != UIBackgroundTaskInvalid )
//    {
//        [[UIApplication sharedApplication] endBackgroundTask: self.taskIdentifier];
//        self.taskIdentifier = UIBackgroundTaskInvalid;
//    }
//}

@end
