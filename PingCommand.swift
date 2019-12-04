//
//  PingCommand.swift
//  AdairNetworking
//
//  Created by Uli Kusterer on 21.11.19.
//  Copyright © 2019 Uli Kusterer. All rights reserved.
//

import Foundation
import Network

class PingCommand: Command {
    static var commandType = CommandType.ping
    private var type = CommandType.ping

    static func register() {
        registerAsType(.ping)
        registerAsType(.pong)
    }
    
    required init(type: CommandType = .ping, stream: InputStream? = nil) {
        self.type = type
    }
    
    func write(to stream: OutputStream) throws {
        try writeType(type, to: stream)
    }
    
    func handle(on connection: NWConnection) throws {
        if type == .ping {
            print("Received ping \(self)")
            let pongCommand = PingCommand(type: .pong)
            try pongCommand.send(on: connection)
        } else {
            print("Received pong \(self)")
        }
    }
}
