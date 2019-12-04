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
        let port = NWEndpoint.Port(rawValue: UInt16(url.port ?? 55555))!
        
        self.connection = NWConnection(host: host, port: port, using: .udp)
        
        self.connection?.stateUpdateHandler = { newState in
            print("State update")
            switch newState {
            case .waiting(let error):
                print("Waiting: \(error)")
            case .failed(let error):
                print("Failed: \(error)")
            case .ready:
                print("Ready.")
                let pingCommand = PingCommand()
                try! pingCommand.send(on: self.connection!) { _ in
                    try! ChatMessageCommand(message: "Hey you, with the wedding dress on.").send(on: self.connection!)
                }
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
        
    func receiveUDP() {
        print("Registering to receive")
        connection!.receiveMessage { [weak connection] data, context, isComplete, nwError in
            print("Receiving UDP")
            if let nwError = nwError { print("error: \(nwError)"); connection?.cancel(); return }
            if isComplete {
                if let data = data, data.count > 0 {
                    print("Received: \(data)")
                    if let command = command(from: data) {
                        do {
                            try command.handle(on: connection!)
                        } catch {
                            print("Error \(error) in command. Disconnecting.")
                            connection?.cancel()
                        }
                    } else {
                        print("Unknown command. Disconnecting.")
                        connection?.cancel()
                    }
                } else {
                    print("Data is empty")
                }
            } else {
                print("Not complete.")
            }
        }
        print("Registered to receive")
    }
}

PingCommand.register()
ChatMessageCommand.register()

let client = Client()
client.connect(to: URL(string: "udp://127.0.0.1:55555")!)

RunLoop.main.run()
