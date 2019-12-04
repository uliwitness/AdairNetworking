//
//  ChatMessageCommand.swift
//  AdairNetworking
//
//  Created by Uli Kusterer on 21.11.19.
//  Copyright © 2019 Uli Kusterer. All rights reserved.
//

import Foundation
import Network

class ChatMessageCommand: Command {
    static var commandType = CommandType.chatMessage
    
    var message = ""
    
    required init(type: CommandType = .chatMessage, stream: InputStream? = nil) {
        if let stream = stream {
            message = try! stream.readString()
        }
    }
    
    convenience init(message: String) {
        self.init()
        self.message = message
    }
        
    func write(to stream: OutputStream) throws {
        try writeType(.chatMessage, to: stream)
        try stream.write(message)
    }
    
    func handle(on connection: NWConnection) throws {
        print("Received message \"\(message)\"")
    }
}
