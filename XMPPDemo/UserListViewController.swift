//
//  UserListViewController.swift
//  XMPPDemo
//
//  Created by Ravi on 19/08/18.
//  Copyright © 2018 naman vaishnav. All rights reserved.
//

import UIKit

class UserListViewController: UIViewController {

    @IBOutlet weak var tblView: UITableView!
    
    var contactList = [XMPPUserCoreDataStorageObject]() {
        didSet {
            tblView.reloadData()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        XMPP_CONTROLLER.userChatList = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension UserListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        let contact = contactList[indexPath.row]
        
        cell?.textLabel?.text = contact.nickname
        cell?.selectionStyle = .none
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatVC = storyboard?.instantiateViewController(withIdentifier: "ChatScreenVC") as! ChatScreenVC
        chatVC.user = contactList[indexPath.row]
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
}
