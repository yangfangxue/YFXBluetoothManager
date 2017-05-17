//
//  YFXBluetoothManager.h
//  YFXBluetoothManager
//
//  Created by fangxue on 17/1/17.
//  Copyright © 2017年 fangxue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#define kServiceUUID               @"" //设备服务的UUID
#define kOutPutcharacteristicUUID  @"" //连接的设备特征(通道)输出的UUID
#define kInputCharacteristicUUID   @"" //连接的设备特征(通道)输入的UUID
//0-未知 1-重置中 2-不支持 3-非法 4-关闭 5-开启 6-连接失败 7-连接成功
typedef enum : NSUInteger {
    Unknown = 0,
    Resetting,
    Unsupported,
    Unauthorized,
    PoweredOff,
    PoweredOn,
    Fail,
    Connect
}blueToolState;//0-5跟系统蓝牙状态相同

@protocol YFXBluetoothManagerDelegate <NSObject>

@optional

- (void)updateDevices:(NSArray *)devices; //搜索到设备回调
- (void)revicedMessage:(NSData *)msg;     //接受到数据回调
- (void)updateStatue:(blueToolState)state;//蓝牙状态改变回调

@end

@interface YFXBluetoothManager : NSObject

@property (weak, nonatomic) id<YFXBluetoothManagerDelegate> delegate;
/*
 *  单例
 *
 *  @return YFXBluetoothManager
 */
+ (instancetype)shareBLEManager;
/*
 *  获取蓝牙状态
 */
- (blueToolState)getBLEStatue;
/**
 *  查找设备
 */
- (void)scanDevice;
/**
 *  停止查找设备
 */
- (void)stopScanDevice;
/**
 *  连接设备
 */
- (void)connectDeviceWithCBPeripheral:(CBPeripheral *)peripheral;
/**
 *  断开连接
 */
- (void)disconnectDevice;

/**
 *  发送消息
 *
 *  @param msg  消息
 */
- (void)sendMsg:(NSData* )msg;

@end
