//
//  SortedLinesFile.swift
//  WordSuggestionsEngine
//
//  A read-only, memory-mapped text file whose lines are sorted by raw UTF-8 bytes.
//  Each line is either "key" or "key\tvalue". Lookups binary-search the mapped bytes,
//  so nothing is parsed up front and almost nothing lives on the heap: the file pages
//  are clean memory that iOS can drop under pressure. This replaces decoding JSON into
//  Swift dictionaries, which peaked at ~37 MB inside the ~48–70 MB keyboard limit.
//
//  Files are produced by scripts/build_dictionaries.py.
//

import Foundation

public final class SortedLinesFile {
    private let data: Data
    /// Byte offset of the first character of every line.
    private let lineStarts: [UInt32]

    public var count: Int { lineStarts.count }

    public init(url: URL) throws {
        data = try Data(contentsOf: url, options: .alwaysMapped)
        var starts: [UInt32] = []
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            guard !bytes.isEmpty else { return }
            starts.reserveCapacity(bytes.count / 12)
            starts.append(0)
            for index in 0..<bytes.count where bytes[index] == 0x0A && index + 1 < bytes.count {
                starts.append(UInt32(index + 1))
            }
        }
        lineStarts = starts
    }

    /// Whether a line with exactly this key exists.
    public func contains(_ key: String) -> Bool {
        value(for: key) != nil
    }

    /// The text after the tab for `key`; an empty string if the line has no value; nil if absent.
    public func value(for key: String) -> String? {
        let keyBytes = Array(key.utf8)
        guard !keyBytes.isEmpty else { return nil }
        return data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> String? in
            var low = 0
            var high = lineStarts.count - 1
            while low <= high {
                let mid = (low + high) / 2
                let (order, keyEnd) = compare(keyBytes, toLineAt: Int(lineStarts[mid]), in: bytes)
                if order == 0 {
                    var end = keyEnd
                    while end < bytes.count, bytes[end] != 0x0A { end += 1 }
                    let valueStart = keyEnd < end ? keyEnd + 1 : keyEnd // skip the tab
                    return String(decoding: UnsafeRawBufferPointer(rebasing: bytes[valueStart..<end]), as: UTF8.self)
                }
                if order < 0 { low = mid + 1 } else { high = mid - 1 }
            }
            return nil
        }
    }

    /// Whole lines (key and value) whose key starts with `prefix`, in file order.
    /// Scans at most `limit` lines, so very short prefixes stay cheap.
    public func lines(withPrefix prefix: String, limit: Int) -> [String] {
        let prefixBytes = Array(prefix.utf8)
        guard !prefixBytes.isEmpty, !lineStarts.isEmpty else { return [] }
        return data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [String] in
            // Lower bound: first line whose key is >= prefix.
            var low = 0
            var high = lineStarts.count
            while low < high {
                let mid = (low + high) / 2
                if keyPrecedes(lineAt: Int(lineStarts[mid]), prefixBytes, in: bytes) { low = mid + 1 } else { high = mid }
            }
            var result: [String] = []
            var index = low
            while index < lineStarts.count, result.count < limit {
                let start = Int(lineStarts[index])
                guard start + prefixBytes.count <= bytes.count,
                      zip(prefixBytes.indices, prefixBytes).allSatisfy({ bytes[start + $0] == $1 }) else { break }
                var end = start
                while end < bytes.count, bytes[end] != 0x0A { end += 1 }
                result.append(String(decoding: UnsafeRawBufferPointer(rebasing: bytes[start..<end]), as: UTF8.self))
                index += 1
            }
            return result
        }
    }

    /// Whether the key of the line at `start` sorts strictly before `prefix`.
    private func keyPrecedes(lineAt start: Int, _ prefix: [UInt8], in bytes: UnsafeRawBufferPointer) -> Bool {
        var lineIndex = start
        for byte in prefix {
            let lineKeyEnded = lineIndex >= bytes.count || bytes[lineIndex] == 0x09 || bytes[lineIndex] == 0x0A
            if lineKeyEnded { return true }        // the line's key is a shorter prefix of `prefix`
            if bytes[lineIndex] != byte { return bytes[lineIndex] < byte }
            lineIndex += 1
        }
        return false                                // the line's key starts with `prefix`
    }

    /// Compares the line's key with `key`. Returns (-1 if line < key, 0 if equal, 1 if line > key)
    /// and the offset where the line's key ends (at the tab or newline).
    private func compare(_ key: [UInt8], toLineAt start: Int, in bytes: UnsafeRawBufferPointer) -> (Int, Int) {
        var lineIndex = start
        var keyIndex = 0
        while true {
            let lineKeyEnded = lineIndex >= bytes.count || bytes[lineIndex] == 0x09 || bytes[lineIndex] == 0x0A
            if keyIndex == key.count { return (lineKeyEnded ? 0 : 1, lineIndex) }
            if lineKeyEnded { return (-1, lineIndex) }
            let lineByte = bytes[lineIndex]
            let keyByte = key[keyIndex]
            if lineByte != keyByte { return (lineByte < keyByte ? -1 : 1, lineIndex) }
            lineIndex += 1
            keyIndex += 1
        }
    }
}
