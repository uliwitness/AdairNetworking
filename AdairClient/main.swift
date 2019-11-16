//
//  main.swift
//  AdairClient
//
//  Created by Uli Kusterer on 16.11.19.
//  Copyright © 2019 Uli Kusterer. All rights reserved.
//

import Foundation
import Network

class Client {
    var connection: NWConnection?
    
    func connect(to url: URL) {
        let host: NWEndpoint.Host = .name(url.host!, nil)
        let port = NWEndpoint.Port(rawValue: UInt16( url.port ?? 55555))!
        
        self.connection = NWConnection(host: host, port: port, using: .udp)
        
        self.connection?.stateUpdateHandler = { newState in
            switch newState {
            case .waiting(let error):
                print("Waiting: \(error)")
            case .failed(let error):
                print("Failed: \(error)")
            case .ready:
                print("Ready.")
                self.sendUDP("Hello!")
                self.receiveUDP()
            case .setup:
                print("Setup.")
            case .cancelled:
                print("Cancelled.")
            case .preparing:
                print("Preparing.")
            default:
                print("Unknown state!")
            }
        }
        
        self.connection?.start(queue: .global())
        print("Client Started.")
    }
    
    func sendUDP(_ content: Data) {
        self.connection?.send(content: content, completion: NWConnection.SendCompletion.contentProcessed({ error in
            if let error = error {
                print("Error sending data: \(error)")
            } else {
                print("Data was sent.")
            }
        }))
    }
    
    func sendUDP(_ content: String) {
        print("Sending: \(content)")
        let contentToSendUDP = content.data(using: String.Encoding.utf8)!
        sendUDP(contentToSendUDP)
    }
    
    func receiveUDP() {
        self.connection?.receiveMessage { [weak connection] data, context, isComplete, error in
            if isComplete {
                if data != nil {
                    let backToString = String(data: data!, encoding: .utf8)!
                    print("Received: \(backToString)")
                } else {
                    print("Data is nil")
                }
                connection?.cancel()
            } else {
                print("Not complete.")
            }
        }
    }
}

let client = Client()
client.connect(to: URL(string: "udp://127.0.0.1:55555")!)

RunLoop.main.run()
