//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        tableView.delegate = self
        tableView.dataSource = self
        //Set title in navigation bar
        title = K.appName
        //Hide the back button from navigation bar
        navigationItem.hidesBackButton = true
        
        //Register message cell
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        loadMessages()
    }
    
    func loadMessages() {
        
        //User send messages from chat view and store to db. Get message from db
        //Evety time when the message was sent, the below method would trigger
        //order method can order the collection
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener { querySnapShot, error in
            //clear the previous messages, so that evety time when the user sending the message, previous message sent to table view again(only show the message the user send currently)
            self.messages = []
            if let e = error {
                print("There was an issue retrieving data from Firestore, \(e)")
            } else {
                if let snapshotDocuments = querySnapShot?.documents {
                    //Get each message from an array
                    for doc in snapshotDocuments {
                        //Message and sender was stored in data(), hence get those information from data()
                        let data = doc.data()
                        //Get the message body and sender from db and store in Message array
                        if let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String {
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            //Reload data if the data was not load in the tableview(because of the internet connection)
                            DispatchQueue.main.async {
                                //This method will trigger the two tableview methods below
                                self.tableView.reloadData()
                                let indexpath = IndexPath(row: self.messages.count - 1, section: 0)
                                //Scroll to very end of the message array
                                self.tableView.scrollToRow(at: indexpath, at: .top, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        //Only if the sender is the curent user
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email {
            //If user typed something in text field, this message would store in db
            db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.senderField: messageSender,K.FStore.bodyField: messageBody,
                //Current time when sending message
                K.FStore.dateField: Date().timeIntervalSince1970]) { error in
                if let e = error {
                    print("There was a issue saving data to FireStore, \(e)")
                } else {
                    //If the message store to the db successfully, invoke this block
                    print("Successfully saved data.")
                    //If inside the closure, and need to update the user interface, always need to add DispatchQueue.main.async
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        do {
          try Auth.auth().signOut()
            //navigate to WelcomeViewController
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
    
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return how many rows want to present in table view
        return messages.count
    }
    
    //What needs to be display to the table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        //Present the text in the table view/ link table view with message cell
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.body
        
        //This is the message from the curret user(me)
        if message.sender == Auth.auth().currentUser?.email {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        } else {
            //This is a message from other sender
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        
        return cell
    }
}

//extension ChatViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        //print row in console
//        print(indexPath.row)
//    }
//}
