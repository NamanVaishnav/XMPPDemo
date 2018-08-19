//
//  XMPPController.swift
//  XMPPDemo
//
//  Created by Ravi Goswami on 19/08/18.
//  Copyright © 2018 Mammoth. All rights reserved.
//

import UIKit
import XMPPFramework


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class XMPPController: NSObject {

    static let sharedInstance = XMPPController()
    
    var pendingMessageList = [String]()
	var xmppStream: XMPPStream
	var xmppReconnect: XMPPReconnect
    var xmppStreamManagement: XMPPStreamManagement
    var xmppRetransmission: XMPPRetransmission
	
    var xmppRoster: XMPPRoster
	var xmppRosterStorage: XMPPRosterCoreDataStorage
    
//    var xmppServiceDiscovery: XMPPServiceDiscovery
//    var xmppCapabilities: XMPPCapabilities
//    var xmppCapabilitiesMyFeatures: Set<String> {
//        didSet {
//            xmppCapabilities.recollectMyCapabilities()
//        }
//    }
    
    
    var userChatList:UserListViewController?
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var contactList = [XMPPUserCoreDataStorageObject]() {
        didSet {
            userChatList?.contactList = contactList
        }
    }
    
    var xmppLastActivity:XMPPLastActivity
    
    var xmppAutoTime:XMPPAutoTime
    var xmppPing:XMPPPing
    var xmppAutoPing:XMPPAutoPing
    
	var xmppMessageArchivingStorage: XMPPMessageArchivingCoreDataStorage
	var xmppMessageArchiveManagement: XMPPMessageArchiveManagement
//    var xmppRoomLightCoreDataStorage: XMPPRoomLightCoreDataStorage
	var xmppMessageDeliveryReceipts: XMPPMessageDeliveryReceipts

    var xmppOneToOneChat: XMPPOneToOneChat
//    var xmppMUCLight: XMPPMUCLight
//    let mucLightServiceName = "muclight.erlang-solutions.com" // TODO: service discovery
//    var roomsLight = [XMPPRoomLight]() {
//        willSet {
//            for removedRoom in (roomsLight.filter { !newValue.contains($0) }) {
//                xmppMessageArchiveManagement.removeDelegate(removedRoom)
//                xmppRetransmission.removeDelegate(removedRoom)
//                xmppOutOfBandMessaging.removeDelegate(removedRoom)
//                removedRoom.removeDelegate(self)
//                removedRoom.removeDelegate(self.xmppRoomLightCoreDataStorage)
//                removedRoom.deactivate()
//            }
//        }
//        didSet {
//            for insertedRoom in (roomsLight.filter { !oldValue.contains($0) }) {
//                insertedRoom.shouldStoreAffiliationChangeMessages = true
//                insertedRoom.activate(xmppStream)
//                insertedRoom.addDelegate(self, delegateQueue: .main)
//                insertedRoom.addDelegate(self.xmppRoomLightCoreDataStorage, delegateQueue: insertedRoom.moduleQueue)
//                xmppMessageArchiveManagement.addDelegate(insertedRoom, delegateQueue: insertedRoom.moduleQueue)
//                xmppRetransmission.addDelegate(insertedRoom, delegateQueue: insertedRoom.moduleQueue)
//                xmppOutOfBandMessaging.addDelegate(insertedRoom, delegateQueue: insertedRoom.moduleQueue)
//                retrieveMessageHistory(fromArchiveAt: insertedRoom.roomJID, lastPageOnly: true)
//            }
//            roomListDelegate?.roomListDidChange(in: self)
//        }
//    }
//
//    var xmppHttpFileUpload: XMPPHTTPFileUpload
//    var xmppOutOfBandMessaging: XMPPOutOfBandMessaging
//    var xmppOutOfBandMessagingStorage: XMPPOutOfBandMessagingFilesystemStorage
    
    var xmppvCardStorage:XMPPvCardCoreDataStorage?
    var xmppvCardTempModule:XMPPvCardTempModule!

    var password: String = ""
    
    var isXmppConnected = false
		
    weak var roomListDelegate: XMPPControllerRoomListDelegate?
    weak var pushNotificationsDelegate: XMPPControllerPushNotificationsDelegate?
    
    override init() {
        self.xmppStream = XMPPStream()
		self.xmppReconnect = XMPPReconnect()

		// Roster
		self.xmppRosterStorage = XMPPRosterCoreDataStorage.sharedInstance()
		self.xmppRoster = XMPPRoster(rosterStorage: self.xmppRosterStorage)
		self.xmppRoster.autoFetchRoster = true
        self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = true
        self.xmppRoster.autoClearAllUsersAndResources = false
		
        // Service Discovery
//        self.xmppServiceDiscovery = XMPPServiceDiscovery()
        
		// Capabilities
//        self.xmppCapabilities = XMPPCapabilities(capabilitiesStorage: XMPPCapabilitiesCoreDataStorage.sharedInstance())
//        self.xmppCapabilities.autoFetchHashedCapabilities = false
//        self.xmppCapabilities.autoFetchNonHashedCapabilities = false
//        self.xmppCapabilitiesMyFeatures = []
        
		// Delivery Receips
		self.xmppMessageDeliveryReceipts = XMPPMessageDeliveryReceipts()
		self.xmppMessageDeliveryReceipts.autoSendMessageDeliveryReceipts = true
		self.xmppMessageDeliveryReceipts.autoSendMessageDeliveryRequests = true

		// Stream Managment
		self.xmppStreamManagement = XMPPStreamManagement(storage: XMPPStreamManagementDiscStorage())
		self.xmppStreamManagement.autoResume = true
        self.xmppStreamManagement.automaticallyRequestAcks(afterStanzaCount: 5, orTimeout: 1)
        self.xmppRetransmission = XMPPRetransmission(dispatchQueue: .main, storage: XMPPRetransmissionUserDefaultsStorage())

        self.xmppMessageArchivingStorage = XMPPMessageArchivingCoreDataStorage()
        self.xmppMessageArchivingStorage.isOutOfBandMessageArchivingEnabled = true
//        self.xmppRoomLightCoreDataStorage = XMPPRoomLightCoreDataStorage()
        
        self.xmppLastActivity = XMPPLastActivity(dispatchQueue: DispatchQueue.main)
        
        self.xmppPing = XMPPPing(dispatchQueue: DispatchQueue.main)
        self.xmppPing.respondsToQueries = true
        
        self.xmppAutoPing = XMPPAutoPing(dispatchQueue: DispatchQueue.main)
        self.xmppAutoPing.pingInterval = 10
        self.xmppAutoPing.pingTimeout = 5.0
        
        self.xmppAutoTime = XMPPAutoTime(dispatchQueue: DispatchQueue.main)
        
        let filteredMessageArchivingStorage = XMPPRetransmissionMessageArchivingStorageFilter(
            baseStorage: self.xmppMessageArchivingStorage,
            xmppRetransmission: self.xmppRetransmission
        )
        self.xmppOneToOneChat = XMPPOneToOneChat(messageArchivingStorage: filteredMessageArchivingStorage)
        self.xmppOneToOneChat.addDelegate(self.xmppMessageArchivingStorage, delegateQueue: self.xmppOneToOneChat.moduleQueue)
        self.xmppRetransmission.addDelegate(self.xmppOneToOneChat, delegateQueue: self.xmppOneToOneChat.moduleQueue)
//        self.xmppMUCLight = XMPPMUCLight()
        
		self.xmppMessageArchiveManagement = XMPPMessageArchiveManagement()
        self.xmppMessageArchiveManagement.resultAutomaticPagingPageSize = NSNotFound
        self.xmppMessageArchiveManagement.addDelegate(self.xmppOneToOneChat, delegateQueue: self.xmppOneToOneChat.moduleQueue)
        
//        self.xmppHttpFileUpload = MIMHTTPFileUpload()
//        self.xmppOutOfBandMessagingStorage = XMPPOutOfBandMessagingFilesystemStorage()
//        self.xmppOutOfBandMessaging = XMPPOutOfBandMessaging(
//            transferHandler: XMPPOutOfBandHTTPTransferHandler(
//                urlSessionConfiguration: .default,
//                xmpphttpFileUpload: self.xmppHttpFileUpload,
//                uploadServiceJID: XMPPJID(string: "upload.erlang-solutions.com")    // TODO: discover service JID
//            ),
//            storage: self.xmppOutOfBandMessagingStorage
//        )
//        self.xmppOutOfBandMessaging.addDelegate(self.xmppOneToOneChat, delegateQueue: self.xmppOneToOneChat.moduleQueue)
//        self.xmppOutOfBandMessaging.addDelegate(self.xmppMUCLight, delegateQueue: self.xmppMUCLight.moduleQueue)
        
        xmppvCardStorage = XMPPvCardCoreDataStorage.sharedInstance()
        xmppvCardTempModule = XMPPvCardTempModule(vCardStorage: xmppvCardStorage!)
        
        // Activate xmpp modules
        self.xmppLastActivity.activate(self.xmppStream)
        self.xmppAutoTime.activate(self.xmppStream)
        self.xmppPing.activate(self.xmppStream)
        self.xmppAutoPing.activate(self.xmppStream)
        self.xmppReconnect.activate(self.xmppStream)
        self.xmppRoster.activate(self.xmppStream)
//        self.xmppServiceDiscovery.activate(self.xmppStream)
//        self.xmppCapabilities.activate(self.xmppStream)
        self.xmppMessageDeliveryReceipts.activate(self.xmppStream)
        self.xmppStreamManagement.activate(self.xmppStream)
        self.xmppRetransmission.activate(self.xmppStream)
        self.xmppMessageArchiveManagement.activate(self.xmppStream)
        self.xmppOneToOneChat.activate(self.xmppStream)
//        self.xmppMUCLight.activate(self.xmppStream)
//        self.xmppOutOfBandMessaging.activate(self.xmppStream)
//        self.xmppHttpFileUpload.activate(self.xmppStream)
        self.xmppvCardTempModule.activate(self.xmppStream)
        
        // Stream Settings
        self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.allowed
        
        super.init()
        
        // Add delegates
        self.xmppLastActivity.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppAutoTime.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppPing.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppAutoPing.addDelegate(self, delegateQueue: DispatchQueue.main)
		self.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppRoster.addDelegate(self, delegateQueue: DispatchQueue.main)
//        self.xmppServiceDiscovery.addDelegate(self, delegateQueue: DispatchQueue.main)
//        self.xmppCapabilities.addDelegate(self, delegateQueue: DispatchQueue.main)
		self.xmppStreamManagement.addDelegate(self, delegateQueue: DispatchQueue.main)
//        self.xmppMUCLight.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppReconnect.addDelegate(self, delegateQueue: DispatchQueue.main)
	}

    func setStreamCredentials(_ hostName: String?, userJID: XMPPJID, hostPort: UInt16 = 5222, password: String) {
        if let host = hostName, hostName?.count > 0 {
            self.xmppStream.hostName = host
        }
        self.xmppStream.myJID = UIDevice.current.identifierForVendor.map { userJID.withNewResource($0.uuidString) } ?? userJID
        self.xmppStream.hostPort = hostPort
        self.password = password
    }
    
    fileprivate func loginToXmpp() {
        // Override point for customization after application launch.
        
        //Login into XMPP
        let auth = AuthenticationModel(jidString: "naman"+DOMAIN_NAME, serverName: SERVER_NAME, password: "asdasd")
        auth.save()
        self.configureAndStartStream()
    }
    
    func configureAndStartStream() {
        _ = XMPP_CONTROLLER.connect()
    }
    
	func connect() -> Bool {
        
		if !self.xmppStream.isDisconnected() {
			return true
		}
		
        guard let authModel =  AuthenticationModel.load() else {
            loginToXmpp()
            return false
        }

        self.setStreamCredentials(authModel.serverName, userJID: authModel.jid, password: authModel.password)
        self.xmppReconnect.manualStart()
        
        return true
	}

	func disconnect() {
//        if let user = APP_DELEGATE.activeChatUser {
//            let message = DDXMLElement(name: "message")
//            message.addAttribute(withName: "type", stringValue: "chat")
//            message.addAttribute(withName: "to", stringValue: user.jid.full())
//
//            let xmppMessage = XMPPMessage(from: message)
//            xmppMessage?.addPausedChatState()
//            xmppStream.send(message)
//
//            if let vc = APP_DELEGATE.chatDetailVC, vc.timer != nil, vc.timer.isValid {
//                vc.timer.invalidate()
//            }
//        }
        
		self.goOffLine()
        self.xmppStream.disconnectAfterSending()
	}

    func retrieveMessageHistory(fromArchiveAt archiveJid: XMPPJID? = nil, startingAt startDate: Date? = nil, filteredBy filteringJid: XMPPJID? = nil, lastPageOnly: Bool = false) {
        let queryFields = [
            startDate.map { XMPPMessageArchiveManagement.field(withVar: "start", type: nil, andValue: ($0 as NSDate).xmppDateTimeString())!},
            filteringJid.map { XMPPMessageArchiveManagement.field(withVar: "with", type: nil, andValue: $0.bare())! }
            ].compactMap({$0})
        
        let resultSet = lastPageOnly ? XMPPResultSet(max: NSNotFound, before: "") : XMPPResultSet(max: NSNotFound)
        
        xmppMessageArchiveManagement.retrieveMessageArchive(at: archiveJid ?? xmppStream.myJID.bare(), withFields: queryFields, with: resultSet)
    }

//    func addRoom(withName roomName: String, initialOccupantJids: [XMPPJID]?) {
//        let addedRoom = XMPPRoomLight(jid: XMPPJID(string: mucLightServiceName)!, roomname: roomName)
//        addedRoom.addDelegate(self, delegateQueue: DispatchQueue.main)
//        addedRoom.activate(xmppStream)
//
//        roomsLight.append(addedRoom)
//
//        addedRoom.createRoomLight(withMembersJID: initialOccupantJids)
//    }

    deinit {
        self.tearDownStream()
    }
    
	func tearDownStream() {
        self.xmppStream.removeDelegate(self)
        self.xmppRoster.removeDelegate(self)
//        self.xmppServiceDiscovery.removeDelegate(self)
//        self.xmppCapabilities.removeDelegate(self)
//        self.xmppMUCLight.removeDelegate(self)
        
//        self.roomsLight.forEach { (roomLight) in
//            self.xmppMessageArchiveManagement.removeDelegate(roomLight)
//            self.xmppOutOfBandMessaging.removeDelegate(roomLight)
//            roomLight.removeDelegate(self)
//            roomLight.deactivate()
//        }
        
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext_roster())
        
        self.xmppAutoTime.deactivate()
		self.xmppReconnect.deactivate()
		self.xmppRoster.deactivate()
//        self.xmppServiceDiscovery.deactivate()
//        self.xmppCapabilities.deactivate()
		self.xmppMessageDeliveryReceipts.deactivate()
		self.xmppStreamManagement.deactivate()
        self.xmppRetransmission.deactivate()
		self.xmppMessageArchiveManagement.deactivate()
        self.xmppOneToOneChat.deactivate()
//        self.xmppMUCLight.deactivate()
//        self.xmppOutOfBandMessaging.deactivate()
//        self.xmppHttpFileUpload.deactivate()
        
        self.disconnect()
        
        self.xmppStream.myJID = nil
        self.xmppStream.hostName = nil
        self.password = ""
	}
    
    func getMessage(forID id:String) -> XMPPMessageArchiving_Message_CoreDataObject? {
        let request = NSFetchRequest<XMPPMessageArchiving_Message_CoreDataObject>(entityName: "XMPPMessageArchiving_Message_CoreDataObject")
        
        //        let userPredicate =
        //        let nonEmptyPredicate = NSPredicate(format: "body != \"\"")
        
        request.predicate = NSPredicate(format: "elementID = %@ AND body != \"\"", id)
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.xmppMessageArchivingStorage.mainThreadManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try controller.performFetch()
            if let message = (controller.sections!.compactMap({$0.objects}).flatMap({$0}) as! [XMPPMessageArchiving_Message_CoreDataObject]).filter({$0.body != nil}).first {
                return message
            } else {
                return nil
            }
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func update(_ status:String, forMessageWithID id:String, actualMessage:XMPPMessage? = nil) {
        DispatchQueue.main.async {
            if let message = self.getMessage(forID: id) {
                if status == "SENT" {
                    if message.status != nil && message.status == "PENDING" {
                        message.status = status
                    }
                } else {
                    if status == "DELIVERED" && message.status != nil && message.status == "READ" {
                        return
                    }
                    message.status = status
                    
                    if let timestamp = message.message.delayedDeliveryDate() {
                        if status == "READ" {
                            message.readTimestamp = timestamp
                        } else if status == "DELIVERED" {
                            message.deliverTimestamp = timestamp
                        }
                    } else {
                        if status == "READ" {
                            message.readTimestamp = Date()
                        } else if status == "DELIVERED" {
                            message.deliverTimestamp = Date()
                        }
                    }
                }
                
                print("rv7284 message with id: \(id) is \(status)")
                do {
                    try self.xmppMessageArchivingStorage.mainThreadManagedObjectContext.save()
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func saveMessageFromNotificationData(_ data:[String:AnyObject]) {
        let id = (data["messageId"] as? String) ?? ""
        
        if self.getMessage(forID: id) != nil {
            return
        }
        guard let entity = NSEntityDescription.entity(forEntityName: "XMPPMessageArchiving_Message_CoreDataObject", in: self.xmppMessageArchivingStorage.mainThreadManagedObjectContext) else {return}
        let newMessage = NSManagedObject(entity: entity, insertInto: nil) as! XMPPMessageArchiving_Message_CoreDataObject
        print("Notification data: ",data as NSDictionary)
        guard let fromUserId = data["frm"] as? String else {return}
        guard let body = data["body"] as? String else {return}
        guard let messageId = data["messageId"] as? String else {return}
        //                    guard let date = data["date"] as? Date else {return}
        guard let to = data["to"] as? String else {return}
        
        newMessage.bareJid = XMPPJID(string: fromUserId+"@localhost")
        newMessage.body = body
        newMessage.elementID = messageId
        newMessage.outgoing = 0
        newMessage.status = "DELIVERED"
        newMessage.timestamp = Date()
        newMessage.composing = 1
        newMessage.streamBareJidStr = to + "@localhost"
        newMessage.messageStr = ""
        self.xmppMessageArchivingStorage.mainThreadManagedObjectContext.insert(newMessage)
        do {
            try XMPP_CONTROLLER.xmppMessageArchivingStorage.mainThreadManagedObjectContext.save()
        } catch let error {
            print(error.localizedDescription)
        }
        print("Notification message :\(body) saved")
    }
    
    func generateReadReceiptResponse(forMessage receivedMessage: XMPPMessageArchiving_Message_CoreDataObject) -> XMPPMessage? {
        guard let read = XMLElement(name: "readReceived", xmlns: "urn:xmpp:readReceipts") else { return nil }
        guard let message = XMLElement.element(withName: "message") as? XMLElement  else { return nil }
        message.addAttribute(withName: "type", stringValue: "chat")
        message.addAttribute(withName: "to", stringValue: receivedMessage.bareJid.bare())
        read.addAttribute(withName: "id", stringValue: receivedMessage.elementID)
        message.addChild(read)
        return XMPPMessage(fromElement: message)
    }
    
    func getContactList() {
        let rosterContext = XMPP_CONTROLLER.managedObjectContext_roster()
        
        let entity = NSEntityDescription.entity(forEntityName: "XMPPUserCoreDataStorageObject", in: rosterContext)
        let sd1 = NSSortDescriptor(key: "sectionNum", ascending: true)
        let sd2 = NSSortDescriptor(key: "displayName", ascending: true)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [sd1,sd2]
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: rosterContext, sectionNameKeyPath: "sectionNum", cacheName: nil)
        self.fetchedResultsController?.delegate = self
        do {
            try self.fetchedResultsController?.performFetch()
            let tmpList = fetchedResultsController!.sections!.compactMap({$0.objects}).flatMap({$0}) as! [XMPPUserCoreDataStorageObject]
            if tmpList.count > 0 {
                contactList = tmpList
            }
            
            print("Contact count: ",self.contactList.count)
        } catch let error {
            print("Error while getting data :",error.localizedDescription)
        }
    }

    
//    func updateFCMToken() {
//        let parameters = ["device_id":DEVICE_ID,
//                          "device_token":notificationToken,
//                          "device_type":"ios"]
//        
//        let header: HTTPHeaders = [
//            "Content-Type" : "application/json",
//            "Authorization" : "Bearer " + Constants.USERDEFAULTS.TOKEN
//        ]
//        
//        print(header as NSDictionary)
//        print(parameters as NSDictionary)
//        
//        Alamofire.request(Constants.APIs.UPDATE_TOKEN, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
//            if let error = response.result.error {
//                print("Error updating token: ",error.localizedDescription)
//            } else if let JSON = response.result.value as? [String:AnyObject] {
//                if let success = JSON["success"] as? Bool, success == true {
//                    UserDefaults.standard.set(false, forKey: "UPDATE_TOKEN")
//                }
//            }
//            }.responseString { (response) in
//                print(response)
//        }
//    }
}

extension XMPPController: XMPPStreamDelegate {
    
    func xmppStream(_ sender: XMPPStream!, willSend presence: XMPPPresence!) -> XMPPPresence! {
        if presence.type() == "unavailable" && UIApplication.shared.applicationState == .active {
            return XMPPPresence(type: "available")
        }
        return presence
    }
    
    func xmppStream(_ sender: XMPPStream!, didSend iq: XMPPIQ!) {
        print("send iq")
        print(iq!)
    }
    
    func xmppStream(_ sender: XMPPStream!, didSend presence: XMPPPresence!) {
        print("Sent presence: ",presence!)
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceiveCustomElement element: DDXMLElement!) {
//        print("did receive custome element")
//        print(element!)
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceive presence: XMPPPresence!) {
        print("Received presence at: \(Date()) type \(presence.type()!) from \(presence.fromStr()!)")
//        print(presence!)
    }

	func xmppStreamDidConnect(_ stream: XMPPStream!) {
        self.isXmppConnected = true
		
        let user = stream.myJID.bare() as String
		print("Stream: Connected as user: \(user).")
        
        do {
            try stream.authenticate(withPassword: self.password)
        } catch let error {
            print("Error while authenticating user: ",error.localizedDescription)
        }
	}

	func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
		self.xmppStreamManagement.enable(withResumption: true, maxTimeout: 1000)
		print("Stream: Authenticated")
		
        // TODO: initial presence should not be sent when the stream was resumed
        // However, microblog currently has no persistent storage and depends on
        // initial presence-based last item delivery each time the app is started
        self.goOnline()
//        GROUP_USER_DEFAULT?.set(xmppStream.myJID.user, forKey: "MY_JID")
//        self.xmppServiceDiscovery.discoverInformationAbout(xmppStream.myJID.domain()) // TODO: xmppStream.myJID.bareJID()
//        self.xmppServiceDiscovery.discoverItemsAssociated(with: xmppStream.myJID.domain())
//        self.xmppMUCLight.discoverRooms(forServiceNamed: mucLightServiceName)
        
        
        //Add user to roster
        xmppRoster.addUser(XMPPJID(string: "ravi@localhost"), withNickname: "Ravi")
        xmppRoster.addUser(XMPPJID(string: "naman@localhost"), withNickname: "Naman")
        xmppRoster.addUser(XMPPJID(string: "dhruv@localhost"), withNickname: "Banyo")
        getContactList()
	}
	
	func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
		print("Stream: Fail to Authenticate")
	}
	
    func xmppStreamWasTold(toDisconnect sender: XMPPStream!) {
        print("Stream was told to disconnect.")
    }
    
	func xmppStreamDidDisconnect(_ sender: XMPPStream!, withError error: Error!) {
		print("Stream: Disconnected")
        if !self.isXmppConnected {
            print("Unable to connect to server. Check xmppStream.hostName")
          //  self.xmppReconnect.manualStart()
        }
        self.isXmppConnected = false
	}
    
    func xmppStreamDidChangeMyJID(_ xmppStream: XMPPStream!) {
        print("Stream: new JID: \((xmppStream.myJID.bare() as String))")
    }
	
	func goOnline() {
		let presence = XMPPPresence()
		self.xmppStream.send(presence)
	}
	
	func goOffLine() {
		let presence = XMPPPresence(type: "unavailable")
		self.xmppStream.send(presence)
	}
    
    func xmppStream(_ sender: XMPPStream!, didFailToSend message: XMPPMessage!, error: Error!) {
        print("Error sending message: ",error.localizedDescription)
        print(message!)
    }
    
//    func xmppStream(_ sender: XMPPStream!, didFailToSend iq: XMPPIQ!, error: Error!) {
//        print("Error sending IQ :",error!.localizedDescription)
//        print(iq!)
//    }
    
    func xmppStream(_ sender: XMPPStream!, didReceiveError error: DDXMLElement!) {
        print("Received error")
        print(error!)
    }
    
//    func xmppStream(_ sender: XMPPStream!, didReceiveCustomElement element: DDXMLElement!) {
//        print("Custom Element received")
//        print(element!)
//    }
    
//    func xmppStream(_ sender: XMPPStream!, didSend iq: XMPPIQ!) {
//        print("IQ send")
//        print(iq!)
//    }
//
//    func xmppStream(_ sender: XMPPStream!, didSendCustomElement element: DDXMLElement!) {
//        print("Custome element send")
//        print(element!)
//    }
    
//    func xmppStream(_ sender: XMPPStream!, didSend message: XMPPMessage!) {
//        print("meessage send")
//        print(message!)
//    }
}

extension XMPPController: XMPPStreamManagementDelegate {

	func xmppStreamManagement(_ sender: XMPPStreamManagement!, wasEnabled enabled: DDXMLElement!) {
		print("Stream Management: enabled")
	}

	func xmppStreamManagement(_ sender: XMPPStreamManagement!, wasNotEnabled failed: DDXMLElement!) {
		print("Stream Management: not enabled")
	}
//    func xmppStreamManagement(_ sender: XMPPStreamManagement!, getIsHandled isHandledPtr: UnsafeMutablePointer<ObjCBool>!, stanzaId stanzaIdPtr: AutoreleasingUnsafeMutablePointer<AnyObject?>!, forReceivedElement element: XMPPElement!) {
//        print("Statnza received")
//        print(element!)
//    }
    
    func xmppStreamManagement(_ sender: XMPPStreamManagement!, didReceiveAckForStanzaIds stanzaIds: [Any]!) {
        let stanzas = (stanzaIds as! [NSUUID]).map({$0.uuidString})
        
        let ackMessages = stanzas.map({sender.messageIDs.value(forKey: $0) as? String}).compactMap({$0})
        
        for msgID in ackMessages {
            if let index = pendingMessageList.index(of: msgID) {
                pendingMessageList.remove(at: index)
            }
            sender.messageIDs.setValue(nil, forKey: msgID)
            
            update("SENT", forMessageWithID: msgID)
        }
    }
}

extension XMPPController: XMPPRosterDelegate {
	
	func xmppRoster(_ sender: XMPPRoster!, didReceivePresenceSubscriptionRequest presence: XMPPPresence!) {
		print("Roster: Received presence request from user: \((presence.from().bare() as String))")
        
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceive message: XMPPMessage!) {
        guard message.to().user == sender.myJID.user else {
            return
        }
        
        if message.hasReadReceiptResponse() {
            update("READ", forMessageWithID: message.readReceiptResponseID())
        }
        
        if message.hasReceiptResponse() {
            update("DELIVERED", forMessageWithID: message.receiptResponseID(), actualMessage: message)
        }
    }
    
//    func xmppStreamManagement(_ sender: XMPPStreamManagement!, getIsHandled isHandledPtr: UnsafeMutablePointer<ObjCBool>!, stanzaId stanzaIdPtr: AutoreleasingUnsafeMutablePointer<AnyObject?>!, forReceivedElement element: XMPPElement!) {
//        print("Stanza received")
//        print(element!)
//    }
}

//extension XMPPController: XMPPMUCLightDelegate {
//
//    func xmppMUCLight(_ sender: XMPPMUCLight, didDiscoverRooms rooms: [DDXMLElement], forServiceNamed serviceName: String) {
//        roomsLight = rooms.map { (rawElement) -> XMPPRoomLight in
//            let rawJid = rawElement.attributeStringValue(forName: "jid")
//            let rawName = rawElement.attributeStringValue(forName: "name")!
//            let jid = XMPPJID(string: rawJid)!
//
//            if let existingRoom = (roomsLight.first { $0.roomJID == jid}) {
//                return existingRoom
//            } else {
//                let filteredRoomLightStorage = XMPPRetransmissionRoomLightStorageFilter(baseStorage: xmppRoomLightCoreDataStorage, xmppRetransmission: xmppRetransmission)
//                return XMPPRoomLight(roomLightStorage: filteredRoomLightStorage, jid: jid, roomname: rawName, dispatchQueue: .main)
//            }
//        }
//    }
//
//    func xmppMUCLight(_ sender: XMPPMUCLight, changedAffiliation affiliation: String, roomJID: XMPPJID) {
//        self.xmppMUCLight.discoverRooms(forServiceNamed: mucLightServiceName)
//    }
//}

//extension XMPPController: XMPPRoomLightDelegate {
//    
//    func xmppRoomLight(_ sender: XMPPRoomLight, didCreateRoomLight iq: XMPPIQ) {
//        xmppMUCLight.discoverRooms(forServiceNamed: mucLightServiceName)
//    }
//    
//    func xmppRoomLight(_ sender: XMPPRoomLight, configurationChanged message: XMPPMessage) {
//        roomListDelegate?.roomListDidChange(in: self)
//    }
//}

//extension XMPPController: XMPPCapabilitiesDelegate {
//
//    func myFeatures(for sender: XMPPCapabilities!) -> [Any]! {
//        return Array(xmppCapabilitiesMyFeatures)
//    }
//}

extension XMPPController {
    func managedObjectContext_roster() -> NSManagedObjectContext {
        return self.xmppRosterStorage.mainThreadManagedObjectContext
    }
}

protocol XMPPControllerRoomListDelegate: class {
    
    func roomListDidChange(in controller: XMPPController)
}

protocol XMPPControllerPushNotificationsDelegate: class {
    
    func xmppControllerDidPrepareForPushNotificationsSupport(_ controller: XMPPController)
    func xmppController(_ controller: XMPPController, didReceivePrivateChatPushNotificationFromContact contact: XMPPUser)
    func xmppController(_ controller: XMPPController, didReceiveGroupChatPushNotificationIn room: XMPPRoomLight)
    func xmppController(_ controller: XMPPController, didReceiveChatPushNotificationFromUnknownSenderWithJid senderJid: XMPPJID)
}

extension XMPPController:  XMPPAutoPingDelegate {
    func xmppAutoPingDidSend(_ sender: XMPPAutoPing!) {
        print("Ping send")
    }
    
    func xmppAutoPingDidReceivePong(_ sender: XMPPAutoPing!) {
        print("Pong received")
    }
    
}

extension XMPPController: XMPPMessageArchiveManagementDelegate {
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveFormFields iq: XMPPIQ!) {
        print("Did receive form field")
        print(iq)
    }
    
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFailToReceiveFormFields iq: XMPPIQ!) {
        print("Failed to Receive form fields")
    }
    
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFailToReceiveMessages error: XMPPIQ!) {
        print("Failed to receive messages with error: ",error)
    }
    
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didReceiveMAMMessage message: XMPPMessage!) {
        print("MAM messages: ",message)
    }
    
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement!, didFinishReceivingMessagesWith resultSet: XMPPResultSet!) {
        print("Result set: ",resultSet)
    }
}


extension XMPPController: XMPPServiceDiscoveryDelegate {
//    func xmppServiceDiscovery(_ sender: XMPPServiceDiscovery!, didFailToDiscover iq: XMPPIQ!) {
//        print("Failed to discover:")
//        print(iq!)
//    }
//
//    func xmppServiceDiscovery(_ sender: XMPPServiceDiscovery!, didDiscoverItems items: [Any]!) {
//        print("Discovered items:")
//        print(items)
//    }
//
//    func xmppServiceDiscovery(_ sender: XMPPServiceDiscovery!, didDiscoverInformation items: [Any]!) {
//        print("Discovered Information:")
//        print(items)
//    }
}


extension XMPPController: XMPPLastActivityDelegate {
    func numberOfIdleTimeSeconds(for sender: XMPPLastActivity!, queryIQ iq: XMPPIQ!, currentIdleTimeSeconds idleSeconds: UInt) -> UInt {
        return 6
    }
    
    func xmppLastActivity(_ sender: XMPPLastActivity!, didReceiveResponse response: XMPPIQ!) {
        print("Last active response")
        print(response!)
    }
    
    func xmppLastActivity(_ sender: XMPPLastActivity!, didNotReceiveResponse queryID: String!, dueToTimeout timeout: TimeInterval) {
        print("Did not receive response")
        print(queryID)
    }
}

extension XMPPMessage {
    convenience init(fromElement element: XMLElement?) {
        object_setClass(element, XMPPMessage.self)
        self.init(from: element)
    }
}


extension XMPPController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let list = fetchedResultsController?.sections?.compactMap({$0.objects}).flatMap({$0}) as? [XMPPUserCoreDataStorageObject], list.count > 0 {
            if self.contactList.count != list.count {
                self.contactList = list
            }
        }
    }
}
