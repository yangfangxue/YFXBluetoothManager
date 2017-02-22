//
//  ViewController.m
//  YFX_BluetoothManager
//
//  Created by fangxue on 2017/1/18.
//  Copyright © 2017年 fangxue. All rights reserved.
//
#import "ViewController.h"
#import "YFXBluetoothManager.h"
@interface ViewController ()<YFXBluetoothManagerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    //1.蓝牙管理类单例 掌管着整个APP蓝牙的收发数据、连接、断开等操作
    [YFXBluetoothManager shareBLEManager];
    //2.挂上代理
    [YFXBluetoothManager shareBLEManager].delegate = self;
    
    /*
     断开蓝牙连接
    [[YFXBluetoothManager shareBLEManager] disconnectDevice];
     */
    /*
     APP发送数据给蓝牙外设
     Byte bytes[1];
     bytes[0] = 0x00;
     NSData *data = [NSData dataWithBytes:bytes length:1];
     [[YFXBluetoothManager shareBLEManager] sendMsg:data];
     */
    
    //更多方法请参加 YFXBluetoothManager.h
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //查找蓝牙设备
    [[YFXBluetoothManager shareBLEManager] scanDevice];
}
//搜索到设备回调
- (void)updateDevices:(NSArray *)devices{
    
    //devices为CBPeripheral(外设)对象集合
    
    /*
     连接蓝牙设备的方法 connectDeviceWithCBPeripheral
     */
    [[YFXBluetoothManager shareBLEManager] connectDeviceWithCBPeripheral:devices[0]];
}
//接受到数据回调
- (void)revicedMessage:(NSData *)msg{
    
    NSLog(@"接受到的数据 = %@",msg);
}
//蓝牙状态改变回调
- (void)updateStatue:(blueToolState)state{
    /*
     Unknown = 0, //未知
     Resetting,   //重置中
     Unsupported, //不支持
     Unauthorized,//未经授权的
     PoweredOff,  //关闭
     PoweredOn,   //打开
     */
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
