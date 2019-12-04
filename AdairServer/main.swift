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
    var preLoginTimeout = TimeInterval(5.0)
    var postLoginTimeout = TimeInterval(30.0)

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
        connection.receiveMessage { [weak connection] data, context, isComplete, nwError in
            if let nwError = nwError { print("error: \(nwError)"); connection?.cancel(); return }
            if isComplete {
                if let data = data, data.count > 0 {
                    print("Received: \(data)")
                    if let command = command(from: data) {
                        do {
                            try command.handle(on: connection!)
                        } catch {
                            print("Error \(error) in command. Disconnecting.")
                            connection!.cancel()
                        }
                    } else {
                        print("Error no command. Disconnecting.")
                        connection!.cancel()
                    }
                } else {
                    print("Data is empty")
                }
            } else {
                print("Not complete.")
            }
        }
    }
}

PingCommand.register()
ChatMessageCommand.register()

let server = Server()
server.listen(on: 55555)

RunLoop.main.run()
