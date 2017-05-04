//
//  MMLocationManager.h
//  DemoBackgroundLocationUpdate
//
//  Created by Ralph Li on 7/20/15.
//  Copyright (c) 2015 LJC. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;
@import UIKit;

@interface MMLocationManager : CLLocationManager

+ (instancetype)sharedManager;

@property (nonatomic, assign) CGFloat minSpeed;
@property (nonatomic, assign) CGFloat minFilter;
@property (nonatomic, assign) CGFloat minInteval;

//@property (nonatomic, strong) NSMutableArray *locationMutableArray; //存放用户位置的数组
+ (NSMutableArray *) getlocationMutableArray;
+ (CGFloat) getlastlatitude;
+ (CGFloat) getlastlongitude;


@end
