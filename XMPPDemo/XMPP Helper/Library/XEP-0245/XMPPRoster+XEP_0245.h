//
//  XMPPRoster+XEP_0245.h
//  Mangosta
//
//  Created by Piotr Wegrzynek on 24/05/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@interface XMPPRoster (XEP_0245)

- (NSString *)meCommandSubstitutionForMessage:(XMPPMessage *)message;

@end
