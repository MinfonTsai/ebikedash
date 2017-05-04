//
//  FirstViewController.m
//  ebikedash
//
//  Created by Minfon on 2016/10/17.
//  Copyright © 2016年 Minfon. All rights reserved.
//

#import "FirstViewController.h"
#import "MMLocationManager.h"

@interface FirstViewController ()

 @property (nonatomic) int lastdraw_count;

@end

@implementation FirstViewController


#pragma mark - 位置管理者加载
- (CLLocationManager *)localManager
{
    if (_localManager == nil)
    {
        _localManager = [[CLLocationManager alloc]init];
        
        //设置定位的精度
        [_localManager setDesiredAccuracy:kCLLocationAccuracyBest];
        
        //位置信息更新最小距离
        _localManager.distanceFilter = 10;
        
        //设置代理
        _localManager.delegate = self;
        
        //如果没有授权则请求用户授权,
        //因为 requestAlwaysAuthorization 是 iOS8 后提出的,需要添加一个是否能响应的条件判断,防止崩溃
        if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusNotDetermined && [_localManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_localManager requestAlwaysAuthorization];
        }
        
        //创建存放位置的数组
        // _locationMutableArray = [[NSMutableArray alloc] init];
    }
    return _localManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    [[MMLocationManager sharedManager] requestAlwaysAuthorization];
#endif
    
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    [[MMLocationManager sharedManager] setAllowsBackgroundLocationUpdates:YES];
#endif
    
    [[MMLocationManager sharedManager] startUpdatingLocation];
    
    
    _latitudeDelta = 0.045;
    _longitudeDelta = 0.045;
    
    //全屏显示地图并设置地图的代理  // 不全屏則不執行下一行, 使用UI定義的大小
   // _mapView = [[MKMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
   
    _mapView.delegate = self;
   
    //是否启用定位服务
    if ([CLLocationManager locationServicesEnabled]){
        NSLog(@"开始定位");
        //调用 startUpdatingLocation 方法后,会对应进入 didUpdateLocations 方法
        [self.localManager startUpdatingLocation];
    }
    else{
        
        NSLog(@"定位服务为关闭状态,无法使用定位服务");
    }
    
    //用户位置追踪
    _mapView.userTrackingMode = MKUserTrackingModeFollow;
    /**
     地图的样式:
     MKMapTypeStandard, 标准地图
     MKMapTypeSatellite, 卫星地图
     MKMapTypeHybrid, 混合地图
     MKMapTypeSatelliteFlyover, 卫星立体地图
     MKMapTypeHybridFlyover, 混合立体地图
     */
    _mapView.mapType = MKMapTypeStandard;
    
    
    /*
     // Start heading updates.  //頭朝的指向事件
     if ([CLLocationManager headingAvailable]) {
     self.localManager.headingFilter = 5;
     [self.localManager startUpdatingHeading];
     // [_mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
     }
     */
    
    
    [self.view addSubview:_mapView];
    
    _view_L11.layer.borderWidth = 1;
    _view_L12.layer.borderWidth = 1;
    _view_L21.layer.borderWidth = 1;
    _view_L22.layer.borderWidth = 1;
    _view_L11.layer.borderColor =[[UIColor grayColor] CGColor];
    _view_L12.layer.borderColor =[[UIColor grayColor] CGColor];
    _view_L21.layer.borderColor =[[UIColor grayColor] CGColor];
    _view_L22.layer.borderColor =[[UIColor grayColor] CGColor];
    
    _lastdraw_count = 0;
    
}

- (void)locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)newHeading
{
    
    double rotation = newHeading.magneticHeading * 3.14159 / 180;
    CGPoint anchorPoint = CGPointMake(0, -23); // The anchor point for your pin
    
    [_mapView setTransform:CGAffineTransformMakeRotation(-rotation)];
    
    [[_mapView annotations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MKAnnotationView * view = [_mapView viewForAnnotation:obj];
        
        [view setTransform:CGAffineTransformMakeRotation(rotation)];
        [view setCenterOffset:CGPointApplyAffineTransform(anchorPoint, CGAffineTransformMakeRotation(rotation))];
        
    }];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark- MKMapViewDelegate
/**
 更新用户位置，只要用户改变则调用此方法（包括第一次定位到用户位置）
 第一种画轨迹的方法:我们使用在地图上的变化来描绘轨迹,这种方式不用考虑从 CLLocationManager 取出的经纬度在 mapView 上显示有偏差的问题
 */
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    NSString *latitude = [NSString stringWithFormat:@"%3.5f",userLocation.coordinate.latitude];
    NSString *longitude = [NSString stringWithFormat:@"%3.5f",userLocation.coordinate.longitude];
    NSLog(@"更新的用户位置:纬度:%@, 经度:%@",latitude,longitude);
    
    //设置地图显示范围(如果不进行区域设置会自动显示区域范围并指定当前用户位置为地图中心点)
    MKCoordinateSpan span;
    if( _longitudeDelta == 0.045 && _latitudeDelta ==0.045)
        span = MKCoordinateSpanMake(0.05, 0.05);
    else
        span = MKCoordinateSpanMake( _latitudeDelta, _longitudeDelta );
    
    MKCoordinateRegion region=MKCoordinateRegionMake(userLocation.location.coordinate, span);
    [_mapView setRegion:region animated:true];
    
    NSMutableArray *locationMutableArray;
    locationMutableArray =  [MMLocationManager getlocationMutableArray];
    
    //--------------------------------------
    // 以下一段程序是要補繪出當程式在背景時
    // GPS位置可能在MMLocationManager.m的didUpdateLocations已添加到locationMutableArray數組
    // 所以補畫上走過的軌跡(畫線)
    //--------------------------------------
    while ( locationMutableArray.count > 2 && _lastdraw_count > 4 && (locationMutableArray.count - _lastdraw_count > 2 ) )
    {
        
        NSString *locationStr = [locationMutableArray objectAtIndex:(_lastdraw_count)];
        NSArray *temp = [locationStr componentsSeparatedByString:@","];
        NSString *latitudeStr = temp[0];
        NSString *longitudeStr = temp[1];
        CLLocationCoordinate2D startCoordinate = CLLocationCoordinate2DMake([latitudeStr doubleValue], [longitudeStr doubleValue]);
        
        locationStr = [locationMutableArray objectAtIndex:(_lastdraw_count+1)];
        temp = [locationStr componentsSeparatedByString:@","];
        latitudeStr = temp[0];
        longitudeStr = temp[1];
        CLLocationCoordinate2D endCoordinate= CLLocationCoordinate2DMake([latitudeStr doubleValue], [longitudeStr doubleValue]);
        //开始绘制轨迹
        CLLocationCoordinate2D pointsToUse[2];
        pointsToUse[0] = startCoordinate;
        pointsToUse[1] = endCoordinate;
        //调用 addOverlay 方法后,会进入 rendererForOverlay 方法,完成轨迹的绘制
        MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:2];
        [_mapView addOverlay:lineOne];
        
        _lastdraw_count++;
    }
    //--------------------------------------
    
    
    if ( locationMutableArray.count > 2 ) {  // != 0) {
        
        _lastdraw_count = (int)locationMutableArray.count;
        
        //从位置数组中取出最新的位置数据
        NSString *locationStr = locationMutableArray.lastObject;
        NSArray *temp = [locationStr componentsSeparatedByString:@","];
        NSString *latitudeStr = temp[0];
        NSString *longitudeStr = temp[1];
        CLLocationCoordinate2D startCoordinate = CLLocationCoordinate2DMake([latitudeStr doubleValue], [longitudeStr doubleValue]);
        
        
        //--------------------------------------
        // 以下一段程序是為了判斷目前的值是否和 MMLocationManager中的didUpdateLocations添加的位置数组有無重複
        //--------------------------------------
        CGFloat last_latitude;
        CGFloat last_longitude;
        last_latitude = [MMLocationManager getlastlatitude];
        last_longitude = [MMLocationManager getlastlongitude];
        NSString *latitude_1 = [NSString stringWithFormat:@"%3.6f",last_latitude];
        NSString *longitude_1 = [NSString stringWithFormat:@"%3.6f",last_longitude];
        
        if( [latitude_1 doubleValue]  == [latitudeStr doubleValue] &&  [longitude_1 doubleValue] == [longitudeStr doubleValue]  )
        {
            NSLog(@"重複");
            
            int i = locationMutableArray.count;
            
            NSString *locationStr = [locationMutableArray objectAtIndex:(i-2)];
            NSArray *temp = [locationStr componentsSeparatedByString:@","];
            NSString *latitudeStr = temp[0];
            NSString *longitudeStr = temp[1];
            startCoordinate = CLLocationCoordinate2DMake([latitudeStr doubleValue], [longitudeStr doubleValue]);
            
            NSLog(@"La=%3.6f , Lo=%3.6f",[latitudeStr doubleValue],[longitudeStr doubleValue]);
            
        }
        //--------------------------------------
        
        
        
        
        //当前确定到的位置数据
        CLLocationCoordinate2D endCoordinate;
        endCoordinate.latitude = userLocation.coordinate.latitude;
        endCoordinate.longitude = userLocation.coordinate.longitude;
        
        //移动距离的计算
        double meters = [self calculateDistanceWithStart:startCoordinate end:endCoordinate];
        NSLog(@"移动的距离为%f米",meters);
        
        //为了美化移动的轨迹,移动的位置超过10米,方可添加进位置的数组
        if (meters >= 0){
            
            NSLog(@"添加进位置数组");
            NSString *locationString = [NSString stringWithFormat:@"%f,%f",userLocation.coordinate.latitude, userLocation.coordinate.longitude];
            [ locationMutableArray addObject:locationString];
            
            //开始绘制轨迹
            CLLocationCoordinate2D pointsToUse[2];
            pointsToUse[0] = startCoordinate;
            pointsToUse[1] = endCoordinate;
            //调用 addOverlay 方法后,会进入 rendererForOverlay 方法,完成轨迹的绘制
            MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:2];
            [_mapView addOverlay:lineOne];
            
        }else{
            
            NSLog(@"不添加进位置数组");
        }
    }else{
        
        //存放位置的数组,如果数组包含的对象个数为0,那么说明是第一次进入,将当前的位置添加到位置数组
        NSString *locationString = [NSString stringWithFormat:@"%f,%f",userLocation.coordinate.latitude, userLocation.coordinate.longitude];
        [locationMutableArray addObject:locationString];
    }
}

//当区域改变时调用
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    //获取系统默认定位的经纬度跨度
    // NSLog(@"维度跨度:%f,经度跨度:%f",mapView.region.span.latitudeDelta,mapView.region.span.longitudeDelta);
    _latitudeDelta = mapView.region.span.latitudeDelta;
    _longitudeDelta = mapView.region.span.longitudeDelta;
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay{
    
    if ([overlay isKindOfClass:[MKPolyline class]]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        MKPolylineView *polyLineView = [[MKPolylineView alloc] initWithPolyline:overlay];
        polyLineView.lineWidth = 10; //折线宽度
        polyLineView.strokeColor = [UIColor blueColor]; //折线颜色
        return (MKOverlayRenderer *)polyLineView;
#pragma clang diagnostic pop
    }
    return nil;
}


#pragma mark - CLLocationManagerDelegate
/**
 *  当前定位授权状态发生改变时调用
 *
 *  @param manager 位置管理者
 *  @param status  授权的状态
 */
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:{
            NSLog(@"用户还未进行授权");
            break;
        }
        case kCLAuthorizationStatusDenied:{
            // 判断当前设备是否支持定位和定位服务是否开启
            if([CLLocationManager locationServicesEnabled]){
                
                NSLog(@"用户不允许程序访问位置信息或者手动关闭了位置信息的访问，帮助跳转到设置界面");
                
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL: url];
                }
            }else{
                NSLog(@"定位服务关闭,弹出系统的提示框,点击设置可以跳转到定位服务界面进行定位服务的开启");
            }
            break;
        }
        case kCLAuthorizationStatusRestricted:{
            NSLog(@"受限制的");
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways:{
            NSLog(@"授权允许在前台和后台均可使用定位服务");
            break;
        }
        case kCLAuthorizationStatusAuthorizedWhenInUse:{
            NSLog(@"授权允许在前台可使用定位服务");
            break;
        }
            
        default:
            break;
    }
}
/**
 我们并没有把从 CLLocationManager 取出来的经纬度放到 mapView 上显示
 原因:
 我们在此方法中取到的经纬度依据的标准是地球坐标,但是国内的地图显示按照的标准是火星坐标
 MKMapView 不用在做任何的处理,是因为 MKMapView 是已经经过处理的
 也就导致此方法中获取的坐标在 mapView 上显示是有偏差的
 解决的办法有很多种,可以上网就行查询,这里就不再多做赘述
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // 设备的当前位置
    CLLocation *currLocation = [locations lastObject];
    
    NSString *latitude = [NSString stringWithFormat:@"纬度:%3.5f",currLocation.coordinate.latitude];
    NSString *longitude = [NSString stringWithFormat:@"经度:%3.5f",currLocation.coordinate.longitude];
    NSString *altitude = [NSString stringWithFormat:@"高度值:%3.5f",currLocation.altitude];
    
    NSLog(@"位置发生改变:纬度:%@,经度:%@,高度:%@",latitude,longitude,altitude);
    
    [manager stopUpdatingLocation];
}

//定位失败的回调方法
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"无法获取当前位置 error : %@",error.localizedDescription);
}


#pragma mark - 距离测算
- (double)calculateDistanceWithStart:(CLLocationCoordinate2D)start end:(CLLocationCoordinate2D)end {
    
    double meter = 0;
    
    double startLongitude = start.longitude;
    double startLatitude = start.latitude;
    double endLongitude = end.longitude;
    double endLatitude = end.latitude;
    
    double radLatitude1 = startLatitude * M_PI / 180.0;
    double radLatitude2 = endLatitude * M_PI / 180.0;
    double a = fabs(radLatitude1 - radLatitude2);
    double b = fabs(startLongitude * M_PI / 180.0 - endLongitude * M_PI / 180.0);
    
    double s = 2 * asin(sqrt(pow(sin(a/2),2) + cos(radLatitude1) * cos(radLatitude2) * pow(sin(b/2),2)));
    s = s * 6378137;
    
    meter = round(s * 10000) / 10000;
    return meter;
}

/*

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
*/

  
@end
