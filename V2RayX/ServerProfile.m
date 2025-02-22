//
//  ServerProfile.m
//  V2RayX
//
//  Copyright © 2016年 Cenmrev. All rights reserved.
//

#import "ServerProfile.h"

@implementation ServerProfile

- (ServerProfile*)init {
    self = [super init];
    if (self) {
        [self setProtocol:vmess];
        [self setAddress:@"server.cc"];
        [self setPort:10086];
        [self setUserId:@"00000000-0000-0000-0000-000000000000"];
        [self setAlterId:64];
        [self setLevel:0];
        [self setOutboundTag:@"test server"];
        [self setFlow:none_flow];
        [self setSecurity:none_security];
        [self setNetwork:tcp];
        [self setSendThrough:@"0.0.0.0"];
        [self setStreamSettings:@{
                                  @"security": @"none",
                                  @"tlsSettings": @{
                                          @"serverName": @"server.cc",
                                          @"alpn": @[@"http/1.1"],
                                          @"allowInsecure": [NSNumber numberWithBool:NO],
                                          @"allowInsecureCiphers": [NSNumber numberWithBool:NO]
                                          },
                                  @"xtlsSettings": @{
                                          @"serverName": @"server.cc",
                                          @"alpn": @[@"http/1.1"],
                                          @"allowInsecure": [NSNumber numberWithBool:NO]
                                          },
                                  @"tcpSettings": @{
                                          @"header": @{
                                                  @"type": @"none"
                                                  }
                                          },
                                  @"kcpSettings": @{
                                          @"mtu": @1350,
                                          @"tti": @20,
                                          @"uplinkCapacity": @5,
                                          @"downlinkCapacity": @20,
                                          @"congestion": [NSNumber numberWithBool:NO],
                                          @"readBufferSize": @1,
                                          @"writeBufferSize": @1,
                                          @"header": @{
                                                  @"type": @"none"
                                                  }
                                          },
                                  @"wsSettings": @{
                                          @"path": @"",
                                          @"headers": @{}
                                          },
                                  @"httpSettings": @{
                                          @"host": @[@""],
                                          @"path": @""
                                          },
                                  @"quicSettings": @{
                                          @"security": @"none",
                                          @"key": @"",
                                          @"header": @{ @"type": @"none" }
                                          },
                                  @"grpcSettings": @{
                                          @"multiMode": [NSNumber numberWithBool:NO],
                                          },
                                  @"sockopt": @{}
                                  }];
        [self setMuxSettings:@{
                               @"enabled": [NSNumber numberWithBool:NO],
                               @"concurrency": @8
                               }];
    }
    return self;
}

- (NSString*)description {
    return [[self outboundProfile] description];
}

+ (NSArray*)profilesFromJson:(NSDictionary*)outboundJson {
    // this old: || ![outboundJson[@"protocol"] isEqualToString:@"vmess"]
    if (![outboundJson[@"protocol"] isKindOfClass:[NSString class]] || (
                                                                        ![outboundJson[@"protocol"] isEqualToString:@"vmess"] && ![outboundJson[@"protocol"] isEqualToString:@"vless"]         )) {
        return @[];
    }
    NSMutableArray* profiles = [[NSMutableArray alloc] init];
    NSString* sendThrough = nilCoalescing(outboundJson[@"sendThrough"], @"0.0.0.0");
    if (![[outboundJson valueForKeyPath:@"settings.vnext"] isKindOfClass:[NSArray class]]) {
        return @[];
    }
    for (NSDictionary* vnext in [outboundJson valueForKeyPath:@"settings.vnext"]) {
        ServerProfile* profile = [[ServerProfile alloc] init];
        profile.protocol = searchInArray(outboundJson[@"protocol"], PROTOCOL_LIST);
        profile.address = nilCoalescing(vnext[@"address"], @"127.0.0.1");
        profile.outboundTag = nilCoalescing(outboundJson[@"tag"], @"");
        profile.port = [vnext[@"port"] unsignedIntegerValue];
        if (![vnext[@"users"] isKindOfClass:[NSArray class]] || [vnext[@"users"] count] == 0) {
            continue;
        }
        profile.userId = nilCoalescing(vnext[@"users"][0][@"id"], @"23ad6b10-8d1a-40f7-8ad0-e3e35cd38287");
        profile.alterId = [vnext[@"users"][0][@"alterId"] unsignedIntegerValue];
        profile.level = [vnext[@"users"][0][@"level"] unsignedIntegerValue];
        profile.flow = searchInArray(vnext[@"users"][0][@"flow"], VLESS_FLOW_LIST);
        profile.security = searchInArray(vnext[@"users"][0][@"security"], VMESS_SECURITY_LIST);
        if (outboundJson[@"streamSettings"] != nil) {
            profile.streamSettings = outboundJson[@"streamSettings"];
            profile.network = searchInArray(outboundJson[@"streamSettings"][@"network"], NETWORK_LIST);
        }
        if (outboundJson[@"mux"] != nil) {
            profile.muxSettings = outboundJson[@"mux"];
        }
        profile.sendThrough = sendThrough;
        [profiles addObject:profile];
    }
    return profiles;
}

+ (ServerProfile* _Nullable )readFromAnOutboundDic:(NSDictionary*)outDict {
    NSArray *allProfiles = [self profilesFromJson:outDict];
    if ([allProfiles count] > 0) {
        return allProfiles[0];
    } else {
        return NULL;
    }
}

-(ServerProfile*)deepCopy {
    ServerProfile* aCopy = [[ServerProfile alloc] init];
    aCopy.protocol = self.protocol;
    aCopy.address = [NSString stringWithString:nilCoalescing(self.address, @"")];
    aCopy.port = self.port;
    aCopy.userId = [NSString stringWithString:nilCoalescing(self.userId, @"")];
    aCopy.alterId = self.alterId;
    aCopy.level = self.level;
    aCopy.outboundTag = [NSString stringWithString:nilCoalescing(self.outboundTag, @"")];
    aCopy.flow = self.flow;
    aCopy.security = self.security;
    aCopy.network = self.network;
    aCopy.sendThrough = [NSString stringWithString:nilCoalescing(self.sendThrough, @"")];
    aCopy.streamSettings = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.streamSettings]];
    aCopy.muxSettings = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.muxSettings]];
    return aCopy;
}

- (NSMutableDictionary*)outboundProfile {
    NSMutableDictionary* fullStreamSettings = [NSMutableDictionary dictionaryWithDictionary:streamSettings];
    fullStreamSettings[@"network"] = NETWORK_LIST[network];
    NSDictionary* result =
    @{
      @"sendThrough": sendThrough,
      @"tag": nilCoalescing(outboundTag, @""),
      @"protocol": PROTOCOL_LIST[protocol],
      @"settings": [@{
              @"vnext": @[
                      @{
                          @"address": nilCoalescing([address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] , @""),
                          @"port": [NSNumber numberWithUnsignedInteger:port],
                          @"users": @[
                                  @{
                                      @"id": userId != nil ? [userId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]: @"",
                                      @"alterId": [NSNumber numberWithUnsignedInteger:alterId],
                                      @"flow": VLESS_FLOW_LIST[flow],
                                      @"security": VMESS_SECURITY_LIST[security],
                                      @"level": [NSNumber numberWithUnsignedInteger:level],
                                      @"encryption": @"none"
                                      }
                                  ]
                          }
                      ]
              } mutableCopy],
      @"streamSettings": fullStreamSettings,
      @"mux": muxSettings,
      };
    
//    if([@"vless" isEqualToString:result[@"protocol"]]) {
//        // infra/conf: VLESS users: please add/set "encryption":"none" for every user
//        result[@"settings"][0][@"vnext"][0][@"users"][0][@"encryption"] = @"none";
//    }
//
    return [result mutableCopy];
}

@synthesize protocol;
@synthesize address;
@synthesize port;
@synthesize userId;
@synthesize alterId;
@synthesize level;
@synthesize outboundTag;
@synthesize flow;
@synthesize security;
@synthesize network;
@synthesize sendThrough;
@synthesize muxSettings;
@synthesize streamSettings;
@end
