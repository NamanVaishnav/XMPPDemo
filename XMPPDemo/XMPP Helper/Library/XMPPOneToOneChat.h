//
//  XMPPOneToOneChat.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 22/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@class XMPPOneToOneChatSession;

@interface XMPPOneToOneChat : XMPPModule

- (instancetype)initWithMessageArchivingStorage:(id<XMPPMessageArchivingStorage>)messageArchivingStorage dispatchQueue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithMessageArchivingStorage:(id<XMPPMessageArchivingStorage>)messageArchivingStorage;

- (XMPPOneToOneChatSession *)sessionForUserJID:(XMPPJID *)userJID;

@end

@interface XMPPOneToOneChatSession : NSObject

- (instancetype)init NS_UNAVAILABLE;

@property (readwrite, strong) XMPPAutoTime *autoTime;

- (NSString *)sendMessageWithBody:(NSString *)body;
- (XMPPMessage *)messageWithBody:(NSString *)body;
- (void)sendMessageOnStream:(XMPPMessage *)message;

// TODO: API to close a session

- (GCDMulticastDelegate *)multicastDelegate;

@end

@protocol XMPPOneToOneChatDelegate <NSObject>

-(void)userStatus:(NSString *)status changedForuser:(XMPPJID *)jid withMessage:(XMPPMessage *)message;

@end
