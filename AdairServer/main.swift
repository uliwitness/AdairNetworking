//
//  main.swift
//  AdairServer
//
//  Created by Uli Kusterer on 16.11.19.
//  Copyright © 2019 Uli Kusterer. All rights reserved.
//

import Foundation
import Network

/// Entry in server's list of sessions
struct ClientSession {
    /// User ID if logged in.
    var userID: UInt64?
    /// Session ID user needs to know to talk to us via this session.
    let sessionID: NSUUID
    /// If we don't hear again from this client by this time, we disconnect them.
    let disconnectTime: TimeInterval
}

class Server {
    var listener: NWListener?
    var clients = [String:ClientSession]()
    
    func listen(on port: Int) {
        self.listener = try! NWListener(using: .udp, on: NWEndpoint.Port(rawValue: UInt16(port))!)
        
        self.listener?.newConnectionHandler = { connection in
            print("New connection.")
            connection.stateUpdateHandler = { newState in
                switch newState {
                case .waiting(let error):
                    print("Waiting: \(error)")
                case .failed(let error):
                    print("Failed: \(error)")
                case .ready:
                    print("Ready.")
                    self.receiveUDP(on: connection)
                case .setup:
                    print("Setup.")
                case .cancelled:
                    print("State: Cancelled")
                case .preparing:
                    print("Preparing.")
                default:
                    print("Unknown state!")
                }
            }
            
            connection.start(queue: DispatchQueue(label: "new client"))
        }
        
        self.listener?.start(queue: .global())
        print("Server Started.")
    }
    
    func sendUDP(_ content: Data, on connection: NWConnection) {
        connection.send(content: content, completion: NWConnection.SendCompletion.contentProcessed({ error in
            if let error = error {
                print("Error sending data: \(error)")
            } else {
                print("Data was sent.")
            }
        }))
    }
    
    func sendUDP(_ content: String, on connection: NWConnection) {
        print("Sending: \(content)")
        let contentToSendUDP = content.data(using: String.Encoding.utf8)!
        sendUDP(contentToSendUDP, on: connection)
    }
    
    func receiveUDP(on connection: NWConnection) {
        connection.receiveMessage { [weak connection] data, context, isComplete, error in
            if (isComplete) {
                if (data != nil) {
                    let backToString = String(decoding: data!, as: UTF8.self)
                    print("Received: \(backToString)")
                } else {
                    print("Data is nil")
                }
                self.sendUDP("Server loves you!", on: connection!)
                connection!.cancel()
            } else {
                print("Not complete.")
            }
        }
    }
}

let server = Server()
server.listen(on: 55555)

RunLoop.main.run()
