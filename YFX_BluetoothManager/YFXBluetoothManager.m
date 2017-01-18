//
//  YFXluetoothManager.m
//  YFXluetoothManager
//
//  Created by fangxue on 17/1/17.
//  Copyright © 2017年 fangxue. All rights reserved.
//  
#import "YFXBluetoothManager.h"

@interface YFXBluetoothManager()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, assign) blueToolState bleStatue;

@property (nonatomic, strong) CBCentralManager *centralManager;//蓝牙管理
@property (nonatomic, strong) CBPeripheral *peripheral;//连接的设备信息
@property (nonatomic, strong) CBService *service;//当前服务
@property (nonatomic, strong) CBCharacteristic *inputCharacteristic;//连接的设备特征
@property (nonatomic, strong) NSMutableArray *mPeripherals;//找到的设备

@end

@implementation YFXBluetoothManager

static YFXBluetoothManager *_instance = nil;

+ (instancetype)shareBLEManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _instance = [[YFXBluetoothManager alloc]init];
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],CBCentralManagerOptionShowPowerAlertKey,nil];
        
        _instance.centralManager = [[CBCentralManager alloc] initWithDelegate:_instance queue:dispatch_get_main_queue() options:options];
    });
    return _instance;
}
/**
 *  获取蓝牙状态
 */
- (blueToolState)getBLEStatue{
    
    return _instance.bleStatue;
}
/**
 *  手机蓝牙状态
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    [_instance updateBLEStatue:(int)central.state];
}
/**
 *  查找设备
 */
- (void)scanDevice{
    
    _instance.mPeripherals = [[NSMutableArray alloc]init];//搜索到的设备集合
    
    if (!_instance.centralManager) {
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],CBCentralManagerOptionShowPowerAlertKey,nil];
        
        _instance.centralManager = [[CBCentralManager alloc] initWithDelegate:_instance queue:dispatch_get_main_queue() options:options];
    }

    if(_instance.centralManager.state == CBManagerStatePoweredOn){
        
        NSLog(@"开始搜索蓝牙设备");
        
        [ _instance.centralManager scanForPeripheralsWithServices:nil options:nil];
        
        [_instance updateBLEStatue:(int)_instance.centralManager.state];
        
        }else{
            
          [_instance updateBLEStatue:(int)_instance.centralManager.state];
    }
    
}

/**
 *  找到设备
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    
    //数组containsObject 包含方法 判断一个元素是否在数组中
    if (![_instance.mPeripherals containsObject:peripheral]) {
        
        [_instance.mPeripherals addObject:peripheral];
        
        if (_instance.delegate && [_instance.delegate respondsToSelector:@selector(updateDevices:)]) {
            
            [_instance.delegate updateDevices:_instance.mPeripherals];
        }
    }
}
/**
 *  停止查找设备
 */
- (void)stopScanDevice{
    
    NSLog(@"停止搜索蓝牙设备");
    
    if (_instance.centralManager) {
        
        [_centralManager stopScan];
        
    }
}
/**
 *  连接设备
 */
- (void)connectDeviceWithCBPeripheral:(CBPeripheral *)peripheral{
    
     [_instance.centralManager connectPeripheral:peripheral options:nil];
}

/**
 * 连接成功
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    _instance.peripheral = peripheral;
    
    _instance.peripheral.delegate = _instance;
    
    [_instance.peripheral discoverServices:nil];
    
    [_instance updateBLEStatue:(int)central.state];
    
}
/**
 * 失败
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    
    [_instance updateBLEStatue:(int)central.state];
}
/**
 * 发现服务
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    if (error) {
        
        NSLog(@"发现服务： %@ 错误： %@", peripheral.name, [error localizedDescription]);
        
        return;
    }
    for (CBService *service in peripheral.services) {
        
            dispatch_async(dispatch_get_main_queue(), ^{
              
                [service.peripheral discoverCharacteristics:nil forService:service];
                
            });
    }
    
}
/**
 * 发现特征
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    if (error) {
        
        NSLog(@"发现特征： %@ 错误: %@", peripheral.name, [error localizedDescription]);
        
        return;
    }
    for (CBCharacteristic *c in service.characteristics)
    {
        [peripheral setNotifyValue:YES forCharacteristic:c];
        
        [peripheral readValueForCharacteristic:c];
        
        _inputCharacteristic = c;
    }
}

#pragma mark - 蓝牙断开

/**
 *  断开连接
 */
- (void)disconnectDevice{
    
    NSLog(@"断开蓝牙连接");
    
    if (_instance.peripheral) {
        
        [_instance.centralManager cancelPeripheralConnection:_instance.peripheral];
    }
}

/**
 *  接收断开连接状态
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
     [_instance updateBLEStatue:(int)central.state];
    
}
#pragma mark - 发送及接收消息
/**
 *  发送消息
 *
 *  @param msg  消息
 */
- (void)sendMsg:(NSData* )msg{
    
    NSLog(@"msg %@",msg);
    
    if (msg) {
        
        [_instance.peripheral writeValue:msg forCharacteristic:_inputCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"didWriteValueForCharacteristic -> %@",characteristic);
}

/**
 * 接收数据
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (error) {
        
        NSLog(@"接收数据错误：%@",[error localizedDescription]);
        return;
    }
    NSLog(@"接收到的数据：%@",characteristic.value);
    
    if (_instance.delegate && [_instance.delegate respondsToSelector:@selector(revicedMessage:)]) {
        
        [_instance.delegate revicedMessage:characteristic.value];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
        
    }
    [peripheral readValueForCharacteristic:characteristic];
}
#pragma mark - helper
- (void)updateBLEStatue:(blueToolState)statue{
    
    _instance.bleStatue = statue;
    
    if (_instance.delegate && [_instance.delegate respondsToSelector:@selector(updateStatue:)]) {
        
        [_instance.delegate updateStatue:_instance.bleStatue];
    }
    
    NSLog(@"蓝牙状态为 %d", (int)_instance.bleStatue);
}

@end
