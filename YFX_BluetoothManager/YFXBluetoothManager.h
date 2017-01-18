//
//  YFXBluetoothManager.h
//  YFXBluetoothManager
//
//  Created by fangxue on 17/1/17.
//  Copyright © 2017年 fangxue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef enum : NSUInteger {
    
    Unknown = 0, //未知
    Resetting,   //重置中
    Unsupported, //不支持
    Unauthorized,//未经授权的
    PoweredOff,  //关闭
    PoweredOn,   //打开
    
}blueToolState;//蓝牙状态

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
 *  @return LSBluetoothManager
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
