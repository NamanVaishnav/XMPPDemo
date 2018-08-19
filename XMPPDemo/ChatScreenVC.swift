//
//  ChatScreenVC.swift
//  XMPPDemo
//
//  Created by naman vaishnav on 19/08/18.
//  Copyright © 2018 naman vaishnav. All rights reserved.
//

import UIKit

class ChatScreenVC: UIViewController {
    
    var messageList = [XMPPMessageArchiving_Message_CoreDataObject]() {
        didSet {
            DispatchQueue.main.async {
                self.tblView.reloadData()
                if self.messageList.count > 0 {
                    self.tblView.scrollToRow(at: IndexPath(row: self.messageList.count-1, section: 0), at: .bottom, animated: true)
                }
            }
        }
    }
    
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var txtChat: UITextField!
    
    var lastActiveTime:Date!
    var session:XMPPOneToOneChatSession?  // One to one Chat Handle Through this .
    var user:XMPPUserCoreDataStorageObject!
    var controller:NSFetchedResultsController<XMPPMessageArchiving_Message_CoreDataObject>?
    var uservCard:XMPPvCardTemp?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        fetchChatHistory() // Primarily Fetch Data and List Them
        
        session = XMPP_CONTROLLER.xmppOneToOneChat.session(forUserJID: self.user.jid)
        session?.autoTime = XMPP_CONTROLLER.xmppAutoTime
        XMPP_CONTROLLER.xmppOneToOneChat.addDelegate(self, delegateQueue: DispatchQueue.main)
        XMPP_CONTROLLER.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        title = self.user.nickname
        txtChat.addTarget(self, action: #selector(textfieldDidChange(_:)), for: .editingChanged)
        XMPP_CONTROLLER.xmppvCardTempModule.addDelegate(self, delegateQueue: DispatchQueue.main)
        XMPP_CONTROLLER.xmppvCardTempModule.fetchvCardTemp(for: user.jid, ignoreStorage: true)
    }
    
    // MARK: fetchChatHistory -- Fetch Saved Messages from Local
    func fetchChatHistory() {
        let request = NSFetchRequest<XMPPMessageArchiving_Message_CoreDataObject>(entityName: "XMPPMessageArchiving_Message_CoreDataObject")
        request.predicate = NSPredicate(format: "bareJidStr = %@", user.jidStr)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: XMPP_CONTROLLER.xmppMessageArchivingStorage.mainThreadManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        controller?.delegate = self
        try! self.controller?.performFetch()
        messageList = (controller!.sections!.compactMap({$0.objects}).flatMap({$0}) as! [XMPPMessageArchiving_Message_CoreDataObject]).filter({$0.body != nil})
    }
    
    
    // MARK: sendComposingChatToUser -- Fetch Saved Messages from Local
    func sendComposingChatToUser(_ jid:XMPPJID) {
        let message = DDXMLElement(name: "message")
        message.addAttribute(withName: "type", stringValue: "chat")
        message.addAttribute(withName: "to", stringValue: jid.full())
        
        let xmppMessage = XMPPMessage(from: message)
        xmppMessage?.addComposingChatState()
        XMPP_CONTROLLER.xmppStream.send(message)
    }
    
    // MARK: sendComposingChatToUser -- Fetch Saved Messages from Local
    func sendPauseChatToUser(_ jid:XMPPJID) {
        let message = DDXMLElement(name: "message")
        message.addAttribute(withName: "type", stringValue: "chat")
        message.addAttribute(withName: "to", stringValue: jid.full())
        
        let xmppMessage = XMPPMessage(from: message)
        xmppMessage?.addPausedChatState()
        XMPP_CONTROLLER.xmppStream.send(message)
    }
}


// MARK: TableView Delegate,Datasource
extension ChatScreenVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        let message = messageList[indexPath.row]
        
        cell?.textLabel?.text = message.body
        cell?.detailTextLabel?.text = message.isOutgoing ? XMPP_CONTROLLER.xmppStream.myJID.user : self.user.jid.user
        
        
        if message.isOutgoing {
            cell?.backgroundColor = .gray
        }else{
            cell?.backgroundColor = .lightGray
        }
        
        
//        cell?.textLabel?.textAlignment = message.isOutgoing ? .right : .left
//        cell?.detailTextLabel?.textAlignment = message.isOutgoing ? .right : .left
        
        if message.isOutgoing {
            cell?.accessoryType = (message.status ?? "") == "DELIVERED" ? .checkmark : .none
        } else {
            cell?.accessoryType = .none
        }
        
        
        
        return cell!
    }
}

// MARK: NSFetchedResultsControllerDelegate -- Fetch Saved Messages from Local
extension ChatScreenVC: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let list = (controller.sections?.compactMap({$0.objects}).flatMap({$0}) as? [XMPPMessageArchiving_Message_CoreDataObject])?.filter({$0.body != nil}) {
            DispatchQueue.global(qos: .userInitiated).async {
                if list.count >= self.messageList.count  {
                    self.messageList = list
                }
            }
        }
    }
}


extension ChatScreenVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard let message = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {return false}
        guard let vCard = self.uservCard, let token = vCard.givenName else {return false}
        if message.isEmpty {
            textField.resignFirstResponder()
            return false
        }
        textField.text = ""
        DispatchQueue.main.async {
            if let session = self.session {
                if let xmppMessage = session.message(withBody: message) {
                    XMPP_CONTROLLER.pendingMessageList.append(xmppMessage.elementID())
                    XMPP_CONTROLLER.xmppStream.send(xmppMessage)
                    
                    let status = XMPP_CONTROLLER.getUserStatus(self.user)
                    
                    if status != "Online" {
                        //TODO: send push
                    }
                }
            }
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (textField.text?.isEmpty)! {
            self.sendComposingChatToUser(self.user.jid)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.sendPauseChatToUser(self.user.jid)
    }
    
    @objc func textfieldDidChange(_ sender:UITextField) {
        
    }
    
}


// MARK: XMPPOneToOneChatDelegate -- Chat Status identification
extension ChatScreenVC : XMPPOneToOneChatDelegate{
    func userStatus(_ status: String!, changedForuser jid: XMPPJID!, with message: XMPPMessage!) {
        if jid == XMPP_CONTROLLER.xmppStream.myJID || message.isErrorMessage() || message.wasDelayed() || message.from().user != user.jid.user {
            return
        }
        
        if status == "composing" {
            title = "typing..."
            lastActiveTime = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + INACTIVE_TIME_INTERVAL) {
                let timeDifference = Date().timeIntervalSince(self.lastActiveTime)
                print("Time difference :",timeDifference)
                if timeDifference > INACTIVE_TIME_INTERVAL {
                    self.title = self.user.nickname
                }
            }
        } else {
            title = self.user.nickname
        }
    }
}


extension ChatScreenVC: XMPPvCardTempModuleDelegate {
    func xmppvCardTempModule(_ vCardTempModule: XMPPvCardTempModule!, didReceivevCardTemp vCardTemp: XMPPvCardTemp!, for jid: XMPPJID!) {
        if jid.user == user.jid.user {
            self.uservCard = vCardTemp
        }
    }
}
