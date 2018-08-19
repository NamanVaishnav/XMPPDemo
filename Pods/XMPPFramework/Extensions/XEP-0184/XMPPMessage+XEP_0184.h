#import <Foundation/Foundation.h>
#import "XMPPMessage.h"


@interface XMPPMessage (XEP_0184)

- (BOOL)hasReceiptRequest;
- (BOOL)hasReceiptResponse;
- (BOOL)hasReadReceiptRequest;
- (BOOL)hasReadReceiptResponse;
- (NSString *)receiptResponseID;
- (NSString *)readReceiptResponseID;
- (XMPPMessage *)generateReceiptResponse;
- (XMPPMessage *)generateReadReceiptResponse;
-(BOOL)shouldSendReadReceipt;

- (void)addReceiptRequest;

@end
