//
//  YFXluetoothManager.m
//  YFXluetoothManager
//
//  Created by fangxue on 17/1/17.
//  Copyright © 2017年 fangxue. All rights reserved.
//  
#import "YFXBluetoothManager.h"

#define SCANCUTDOWNTIME 30.0f //查找蓝牙设备超时时间

@interface YFXBluetoothManager()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, assign) blueToolState    bleStatue;
@property (nonatomic, strong) CBCentralManager *centralManager;//蓝牙管理
@property (nonatomic, strong) CBPeripheral     *peripheral;//连接的设备信息
@property (nonatomic, strong) NSMutableArray   *mPeripherals;//找到的设备
@property (nonatomic, strong) NSTimer *scanCutdownTimer; //查找设备倒计时
@property (nonatomic, strong) CBService *service;//当前服务
@property (nonatomic, strong) CBCharacteristic *inputCharacteristic;//连接的设备特征（通道）输入
@property (nonatomic, strong) CBCharacteristic *outPutcharacteristic;//连接的设备特征（通道）输出

@end

@implementation YFXBluetoothManager

static YFXBluetoothManager *_manager = nil;

+ (instancetype)shareBLEManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _manager = [[YFXBluetoothManager alloc]init];
        
        _manager.bleStatue = Unknown;
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],CBCentralManagerOptionShowPowerAlertKey,nil];
        
        _manager.centralManager = [[CBCentralManager alloc] initWithDelegate:_manager queue:dispatch_get_main_queue() options:options];
    });
    return _manager;
}
/**
 *  获取蓝牙状态
 */
- (blueToolState)getBLEStatue{
    
    return _manager.bleStatue;
}
/**
 *  手机蓝牙状态
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    [_manager updateBLEStatue:(int)central.state];
}
/**
 *  查找设备
 */
- (void)scanDevice{
    
    _manager.mPeripherals = [[NSMutableArray alloc]init];//搜索到的设备集合
    
    if (!_manager.centralManager) {
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],CBCentralManagerOptionShowPowerAlertKey,nil];
        
        _manager.centralManager = [[CBCentralManager alloc] initWithDelegate:_manager queue:dispatch_get_main_queue() options:options];
    }

    if(_manager.centralManager.state == CBManagerStatePoweredOn){
        
        NSLog(@"开始搜索蓝牙设备");
        
        [ _manager.centralManager scanForPeripheralsWithServices:nil options:nil];
        
         [_manager updateBLEStatue:PoweredOn];
        
        }else{
            
          [_manager updateBLEStatue:(int)_manager.centralManager.state];
       }
}

/**
 *  找到设备
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    
    //数组containsObject 包含方法 判断一个元素是否在数组中
    if (![_manager.mPeripherals containsObject:peripheral]) {
        
        [_manager.mPeripherals addObject:peripheral];
        
        if (_manager.delegate && [_manager.delegate respondsToSelector:@selector(updateDevices:)]) {
            
            [_manager.delegate updateDevices:_manager.mPeripherals];
        }
    }
}
/**
 *  停止查找设备
 */
- (void)stopScanDevice{
    
    NSLog(@"停止搜索蓝牙设备");
    
    if (_manager.centralManager) {
        
        [_centralManager stopScan];
    }
    
     [_manager.scanCutdownTimer invalidate];
    
    _manager.scanCutdownTimer = nil;
    
}
/**
 *  连接设备
 */
- (void)connectDeviceWithCBPeripheral:(CBPeripheral *)peripheral{
    
     [_manager.centralManager connectPeripheral:peripheral options:nil];
}

/**
 * 连接成功
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    _manager.peripheral = peripheral;
    
    _manager.peripheral.delegate = _manager;
    
    [_manager.peripheral discoverServices:nil];
    
    [_manager updateBLEStatue:Connect];
    
}
/**
 * 失败
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    
    [_manager updateBLEStatue:Fail];
    
}
/**
 * 发现服务
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    if (error) {
        
        return;
    }
    for (CBService *service in peripheral.services) {
        
        if ([service.UUID.UUIDString isEqual:kServiceUUID]){
            
            _manager.service = service;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [peripheral discoverCharacteristics:nil forService:_manager.service];
            });
        }
    }
}
/**
 * 发现特征
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    if (error) {
        
        return;
    }
    for (CBCharacteristic *c in service.characteristics)
    {
        [peripheral setNotifyValue:YES forCharacteristic:c];
        
        [peripheral readValueForCharacteristic:c];
        
        //连接的设备特征（通道）输出
        if ([c.UUID.UUIDString isEqual:kOutPutcharacteristicUUID]){
            
            _outPutcharacteristic = c;
        }
        //连接的设备特征（通道）输入
        if ([c.UUID.UUIDString isEqual:kInputCharacteristicUUID]){
            
            _inputCharacteristic = c;
        }
    }
}

#pragma mark - 蓝牙断开

/**
 *  断开连接
 */
- (void)disconnectDevice{
    
    NSLog(@"断开蓝牙连接");
    
    if (_manager.peripheral) {
        
        [_manager.centralManager cancelPeripheralConnection:_manager.peripheral];
    }
}

/**
 *  接收断开连接状态
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
     [_manager updateBLEStatue:(int)central.state];
    
}
#pragma mark - 发送及接收消息
/**
 *  发送消息
 *
 *  @param msg  消息
 */
- (void)sendMsg:(NSData* )msg{
    
    if (msg) {
        
        if (self.bleStatue==Connect) {
            
            [_manager.peripheral writeValue:msg forCharacteristic:_outPutcharacteristic type:CBCharacteristicWriteWithoutResponse];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    NSLog(@"didWriteValueForCharacteristic -> %@",characteristic);
}
/**
 * 接收数据
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    NSLog(@"接收到的数据：%@",characteristic.value);
    
    if (_manager.delegate && [_manager.delegate respondsToSelector:@selector(revicedMessage:)]) {
        
        [_manager.delegate revicedMessage:characteristic.value];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
        
        return;
    }
    [peripheral readValueForCharacteristic:characteristic];
}
#pragma mark - helper
- (void)updateBLEStatue:(blueToolState)statue{
    
    _manager.bleStatue = statue;
    
    if (_manager.delegate && [_manager.delegate respondsToSelector:@selector(updateStatue:)]) {
        
        [_manager.delegate updateStatue:_manager.bleStatue];
    }
    
    NSLog(@"蓝牙状态为 %d", (int)_manager.bleStatue);
}

@end
