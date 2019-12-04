//
//  Stream+ReadTyped.swift
//  AdairNetworking
//
//  Created by Uli Kusterer on 21.11.19.
//  Copyright © 2019 Uli Kusterer. All rights reserved.
//

import Foundation

enum StreamReadTypedError: Error {
    case stringConversionFailure
    case streamNotOpenError
}

extension InputStream {
    private func read<T: BinaryInteger>(_ type: T.Type = T.self) throws -> T {
        guard streamStatus == .open || streamStatus == .reading || streamStatus == .writing || streamStatus == .atEnd else { throw StreamReadTypedError.streamNotOpenError }
        var num: T = 0
        let tSize = MemoryLayout<T>.size
        UnsafeMutablePointer(&num).withMemoryRebound(to: UInt8.self, capacity: tSize) { (ptr: UnsafeMutablePointer<UInt8>) -> Void in
            self.read(ptr, maxLength: tSize)
        }
        if let error = self.streamError {
            throw error
        }
        return num
    }
    
    func readInt8() throws -> Int8 {
        return try read(Int8.self)
    }
    
    func readUInt8() throws -> UInt8 {
        return try read(UInt8.self)
    }
    
    func readInt16() throws -> Int16 {
        return try read(Int16.self)
    }
    
    func readUInt16() throws -> UInt16 {
        return try read(UInt16.self)
    }
    
    func readInt32() throws -> Int32 {
        return try read(Int32.self)
    }
    
    func readUInt32() throws -> UInt32 {
        return try read(UInt32.self)
    }
    
    func readInt64() throws -> Int64 {
        return try read(Int64.self)
    }
    
    func readUInt64() throws -> UInt64 {
        return try read(UInt64.self)
    }
    
    func readInt() throws -> Int {
        return try Int(read(Int64.self))
    }
    
    func readUInt() throws -> UInt {
        return try UInt(read(UInt64.self))
    }
    
    func readString() throws -> String {
        var result = Data()
        while true {
            var currByte = try readUInt8()
            if currByte == 0 { break }
            result.append(&currByte, count: 1)
        }
        if let stringResult = String(data: result, encoding: .utf8) {
            return stringResult
        } else {
            throw StreamReadTypedError.stringConversionFailure
        }
    }
}

extension OutputStream {
    func write<T: BinaryInteger>(_ inNumber: T) throws {
        guard streamStatus == .open || streamStatus == .reading || streamStatus == .writing || streamStatus == .atEnd else { throw StreamReadTypedError.streamNotOpenError }
        var num = inNumber
        UnsafeMutablePointer(&num).withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) { (ptr: UnsafeMutablePointer<UInt8>) -> Void in
            self.write(ptr, maxLength: MemoryLayout<T>.size)
        }
        if let error = self.streamError {
            throw error
        }
    }
    
    func write(_ str: String) throws {
        guard streamStatus == .open || streamStatus == .reading || streamStatus == .writing || streamStatus == .atEnd else { throw StreamReadTypedError.streamNotOpenError }
        guard let data = str.data(using: .utf8) else { throw StreamReadTypedError.stringConversionFailure }
        data.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) -> Void in
            self.write(ptr.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
        })
        try write(UInt8(0))
    }
}
