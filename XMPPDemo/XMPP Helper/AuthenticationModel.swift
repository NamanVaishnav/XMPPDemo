//
//  AuthenticationModel.swift
//  Mangosta
//
//  Created by Tom Ryan on 3/14/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import Foundation
import XMPPFramework

public struct AuthenticationModel {
	public let jid: XMPPJID
	public let password: String
	public var serverName: String?
    
    static let GROUP_USER_DEFAULT = UserDefaults.standard
	
	public func save() {
		var dict = [String:String]()
		dict["jid"] = self.jid.bare()
		dict["password"] = self.password
		if let server = self.serverName {
			dict["serverName"] = server
		}
        
        AuthenticationModel.GROUP_USER_DEFAULT.set(dict, forKey: "AuthenticationPreferenceName")
	}
	
	public init(jidString: String, password: String) {
		let myJid = XMPPJID.init(string: String(jidString))
		self.jid = myJid!
		self.password = password
	}
	
	public init(jid: XMPPJID, password: String) {
		self.jid = jid
		self.password = password
	}
	
	public init(jidString: String, serverName: String, password: String) {
        self.jid = XMPPJID.init(string: String(jidString))
		self.serverName = serverName
		self.password = password
	}
	
	static public func load() -> AuthenticationModel? {
        if let authDict = GROUP_USER_DEFAULT.object(forKey: "AuthenticationPreferenceName") as? [String:String] {
			let authJidString = authDict["jid"]!
			let pass = authDict["password"]!
			//9376995116
			if let server = authDict["serverName"] {
				return AuthenticationModel(jidString: authJidString, serverName: server, password: pass)
			}
			
            return AuthenticationModel(jid: XMPPJID.init(string: String(authJidString)), password: pass)
		}
        
		return nil
	}
	
	static public func remove() {
        AuthenticationModel.GROUP_USER_DEFAULT.removeObject(forKey: "AuthenticationPreferenceName")
	}
}
