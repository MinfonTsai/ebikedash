//
//  FirstViewController.h
//  ebikedash
//
//  Created by Minfon on 2016/10/17.
//  Copyright © 2016年 Minfon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface FirstViewController : UIViewController

@property (nonatomic, strong) CLLocationManager *localManager;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

//@property (nonatomic, strong) MKMapView *mapView;  //以代碼自訂大小

@property (nonatomic, assign) CGFloat latitudeDelta;
@property (nonatomic, assign) CGFloat longitudeDelta;
@property (weak, nonatomic) IBOutlet UIView *view_L11;
@property (weak, nonatomic) IBOutlet UIView *view_L12;
@property (weak, nonatomic) IBOutlet UIView *view_L21;
@property (weak, nonatomic) IBOutlet UIView *view_L22;




@end

