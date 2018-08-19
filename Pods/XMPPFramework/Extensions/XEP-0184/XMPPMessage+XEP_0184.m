#import "XMPPMessage+XEP_0184.h"
#import "NSXMLElement+XMPP.h"


@implementation XMPPMessage (XEP_0184)

-(BOOL)shouldSendReadReceipt {
    if([self to]
       && ![self isErrorMessage] && ![[[self attributeForName:@"type"] stringValue] isEqualToString:@"groupchat"]
       && [[self elementID] length])
    {
        return YES;
    }
    return NO;
}

- (BOOL)hasReceiptRequest
{
    NSXMLElement *receiptRequest = [self elementForName:@"request" xmlns:@"urn:xmpp:receipts"];
    
    return (receiptRequest != nil);
}


- (BOOL)hasReceiptResponse
{
    NSXMLElement *receiptResponse = [self elementForName:@"received" xmlns:@"urn:xmpp:receipts"];
    
    return (receiptResponse != nil);
}

-(BOOL)hasReadReceiptRequest {
    NSXMLElement *receiptRequest = [self elementForName:@"readRequest" xmlns:@"urn:xmpp:readReceipts"];
    
    return (receiptRequest != nil);
}

-(BOOL)hasReadReceiptResponse {
    NSXMLElement *receiptResponse = [self elementForName:@"readReceived" xmlns:@"urn:xmpp:readReceipts"];
    
    return (receiptResponse != nil);
}

- (NSString *)receiptResponseID
{
    NSXMLElement *receiptResponse = [self elementForName:@"received" xmlns:@"urn:xmpp:receipts"];
    
    return [receiptResponse attributeStringValueForName:@"id"];
}

-(NSString *)readReceiptResponseID
{
    NSXMLElement *receiptResponse = [self elementForName:@"readReceived" xmlns:@"urn:xmpp:readReceipts"];
    
    return [receiptResponse attributeStringValueForName:@"id"];
}

- (XMPPMessage *)generateReceiptResponse
{
    // Example:
    // 
    // <message to="juliet">
    //   <received xmlns="urn:xmpp:receipts" id="ABC-123"/>
    // </message>
    
    NSXMLElement *received = [NSXMLElement elementWithName:@"received" xmlns:@"urn:xmpp:receipts"];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    
    NSString *type = [self type];
    
    if (type) {
        [message addAttributeWithName:@"type" stringValue:type];
    }
    
    NSString *to = [self fromStr];
    if (to)
    {
        [message addAttributeWithName:@"to" stringValue:to];
    }
    
    NSString *msgid = [self elementID];
    if (msgid)
    {
        [received addAttributeWithName:@"id" stringValue:msgid];
    }
    
    [message addChild:received];
    
    return [[self class] messageFromElement:message];
}

-(XMPPMessage *)generateReadReceiptResponse {
    // Example:
    //
    // <message to="juliet">
    //   <received xmlns="urn:xmpp:read" id="ABC-123"/>
    // </message>
    
    NSXMLElement *read = [NSXMLElement elementWithName:@"readReceived" xmlns:@"urn:xmpp:readReceipts"];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    
    NSString *type = [self type];
    
    if (type) {
        [message addAttributeWithName:@"type" stringValue:type];
    }
    
    NSString *to = [self fromStr];
    if (to)
    {
        [message addAttributeWithName:@"to" stringValue:to];
    }
    
    NSString *msgid = [self elementID];
    if (msgid)
    {
        [read addAttributeWithName:@"id" stringValue:msgid];
    }
    
    [message addChild:read];
    
    return [[self class] messageFromElement:message];
}

- (void)addReceiptRequest
{
    NSXMLElement *receiptRequest = [NSXMLElement elementWithName:@"request" xmlns:@"urn:xmpp:receipts"];
    [self addChild:receiptRequest];
}

@end
