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
            }
        }
    }
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var txtChat: UITextField!
    
    var session:XMPPOneToOneChatSession?  // One to one Chat Handle Through this .
    var user:XMPPUserCoreDataStorageObject!
    var controller:NSFetchedResultsController<XMPPMessageArchiving_Message_CoreDataObject>?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        session = XMPP_CONTROLLER.xmppOneToOneChat.session(forUserJID: self.user.jid)
        session?.autoTime = XMPP_CONTROLLER.xmppAutoTime
        
        fetchChatHistory()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchChatHistory() {
        let request = NSFetchRequest<XMPPMessageArchiving_Message_CoreDataObject>(entityName: "XMPPMessageArchiving_Message_CoreDataObject")
        request.predicate = NSPredicate(format: "bareJidStr = %@", user.jidStr)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: XMPP_CONTROLLER.xmppMessageArchivingStorage.mainThreadManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        controller?.delegate = self
        try! self.controller?.performFetch()
        messageList = (controller!.sections!.compactMap({$0.objects}).flatMap({$0}) as! [XMPPMessageArchiving_Message_CoreDataObject]).filter({$0.body != nil})
    }
}

extension ChatScreenVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        let message = messageList[indexPath.row]
        
        cell?.textLabel?.text = message.body
        cell?.detailTextLabel?.text = message.isOutgoing ? XMPP_CONTROLLER.xmppStream.myJID.user : self.user.jid.user
        
        return cell!
    }
}


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
        if message.isEmpty {
            return false
        }
        textField.text = ""
        DispatchQueue.main.async {
            if let session = self.session {
                if let xmppMessage = session.message(withBody: message) {
                    XMPP_CONTROLLER.pendingMessageList.append(xmppMessage.elementID())
                    XMPP_CONTROLLER.xmppStream.send(xmppMessage)
                }
            }
        }
        
        return true
    }
    
    
    
}
