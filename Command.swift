//
//  Command.swift
//  AdairNetworking
//
//  Created by Uli Kusterer on 21.11.19.
//  Copyright © 2019 Uli Kusterer. All rights reserved.
//

import Foundation
import Network

enum CommandType: UInt8 {
    case invalid = 255
    case login = 0 // LoginCommand
    case logout = 1 // LogoutCommand
    case ping = 2 // PingCommand
    case pong = 3 // PingCommand
    case chatMessage = 4 // ChatMessageCommand
}

fileprivate var registeredCommands = [CommandType:Command.Type]()

func command(from data: Data) -> Command? {
    let stream = InputStream(data: data)
    stream.open()
    defer { stream.close() }
    var optRawCommandType: UInt8?
    do {
       optRawCommandType = try stream.readUInt8()
    } catch {
        print("error reading type: \(error)")
        optRawCommandType = CommandType.invalid.rawValue
    }
    if let rawCommandType = optRawCommandType {
        print("Raw command type \(rawCommandType)")
        if let commandType = CommandType(rawValue: rawCommandType) {
            print("\tcommand type \(commandType)")
            if let commandClass = registeredCommands[commandType] {
                print("\tcommandClass \(commandClass)")
                return commandClass.init(type: commandType, stream: stream)
            }
        }
    }
    
    return nil
}

protocol Command: class {
    static var commandType: CommandType { get }
    
    static func registerAsType(_ type: CommandType)
    static func register()

    init(type: CommandType, stream: InputStream?)
    
    func writeType(_ type: CommandType, to stream: OutputStream) throws
    
    func write(to stream: OutputStream) throws
    
    func handle(on connection: NWConnection) throws
    
    func data() throws -> Data
    
    func send(on connection: NWConnection, handler: @escaping (NWError?) -> Void) throws
    func send(on connection: NWConnection) throws
}

extension Command {
    static func registerAsType(_ type: CommandType) {
        registeredCommands[type] = self
    }

    static func register() {
        registeredCommands[self.commandType] = self
    }

    func writeType(_ type: CommandType, to stream: OutputStream) throws {
        try stream.write(type.rawValue)
    }
        
    func handle(on connection: NWConnection) throws {
        print("No override handling message \(self).")
    }
    
    func data() throws -> Data {
        print("Data from message.")
        let messageStream = OutputStream.toMemory()
        messageStream.open()
        try self.write(to: messageStream)
        messageStream.close()
        return messageStream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
    }
    
    func send(on connection: NWConnection, handler: @escaping (NWError?) -> Void) throws {
        let message = try data()
        print("Sending: \(self) \(message)")
        connection.send(content: message, completion: .contentProcessed(handler))
    }

    func send(on connection: NWConnection) throws {
        try send(on: connection, handler: { _ in })
    }
}
