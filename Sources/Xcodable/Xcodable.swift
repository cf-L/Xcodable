
import Foundation

public typealias Xcodable = XEncodable & XDecodable

public typealias NestedSymbol = Character

extension NestedSymbol {
    public static let `default`: Character = "."
}

public protocol DataEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

public protocol DataDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONEncoder: DataEncoder {}
extension JSONDecoder: DataDecoder {}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension PropertyListEncoder: DataEncoder {}
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension PropertyListDecoder: DataDecoder {}

public extension Data {
    func decoded<T: Decodable>(
        using decoder: DataDecoder = JSONDecoder(),
        as type: T.Type = T.self) throws -> T
    {
        return try decoder.decode(type, from: self)
    }
}

public extension Dictionary {
    func decoded<T: Decodable>(
        using decoder: JSONDecoder = JSONDecoder(),
        as type: T.Type = T.self,
        options: JSONSerialization.WritingOptions = .fragmentsAllowed) throws -> T
    {
        let data = try JSONSerialization.data(withJSONObject: self, options: options)
        return try data.decoded(using: decoder, as: type)
    }
}

public extension Array {
    func decoded<T: Decodable>(
        using decoder: JSONDecoder = JSONDecoder(),
        as type: T.Type = T.self,
        options: JSONSerialization.WritingOptions = .fragmentsAllowed) throws -> T
    {
        let data = try JSONSerialization.data(withJSONObject: self, options: options)
        return try data.decoded(using: decoder, as: type)
    }
}

public extension String {
    func decoded<T: Decodable>(
        using decoder: JSONDecoder = JSONDecoder(),
        as type: T.Type = T.self) throws -> T
    {
        return try Data(self.utf8).decoded(using: decoder, as: type)
    }
}
