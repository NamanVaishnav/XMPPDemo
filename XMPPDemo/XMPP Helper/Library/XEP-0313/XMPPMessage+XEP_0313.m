//
//  XMPPMessage+XEP_0313.m
//  Mangosta
//
//  Created by Tom Ryan on 4/8/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

#import "XMPPMessage+XEP_0313.h"
#import "NSXMLElement+XEP_0297.h"
#import "XMPPJID.h"
#import "XMPPMessage.h"
#import "NSXMLElement+XMPP.h"

#define XMLNS_XMPP_MAM @"urn:xmpp:mam:1"

@implementation XMPPMessage (XEP_0313)

- (NSXMLElement *)receivedMessageArchiveResult {

	DDXMLElement *resultElement = [self elementForName:@"result" xmlns:XMLNS_XMPP_MAM];
	
	return [resultElement elementForName:@"forwarded"];
}

- (BOOL)isMessageArchive {
	if ([self receivedMessageArchiveResult]) {
		return YES;
	}
	return NO;
}

- (NSString *)resultId {

	DDXMLElement *resultElement = [self elementForName:@"result" xmlns:XMLNS_XMPP_MAM];
	if(resultElement) {
		return [resultElement attributeStringValueForName:@"id"];
	}

	return nil;
}

- (NSXMLElement *)delayElement {
	DDXMLElement *resultElement = [self elementForName:@"result" xmlns:XMLNS_XMPP_MAM];
	return [[resultElement elementForName:@"forwarded"] elementForName: @"delay"];
}

- (NSString *)delayStamp {
	NSXMLElement *delay = [self delayElement];
	if (delay) {
		return [delay attributeStringValueForName:@"stamp"];
	}
	return nil;
}

- (XMPPMessage *)messageForForwardedArchiveMessage {
	if ([self elementForName:@"result" xmlns:XMLNS_XMPP_MAM]) {
		DDXMLElement *resultElement = [self elementForName:@"result" xmlns:XMLNS_XMPP_MAM];
		DDXMLElement *delayElement = [self delayElement];
		DDXMLElement *internalMessage = [resultElement forwardedMessage];
		
		NSString *resultId = [resultElement attributeStringValueForName:@"id"];
		
        // TODO: [pwe] this method is modifying receiver's "internalMessage" element
        // before fixing, evaluate the impact as it's being called on received messages distributed via multidelegation
		XMPPMessage *message = [XMPPMessage messageFromElement:internalMessage];
		if (delayElement) {
			[message addChild:[delayElement copy]];
		}
		if (resultId) {
			[message addAttributeWithName:@"resultId" stringValue:resultId];
		}
		
		return message;
	}
	return self;
}

@end
