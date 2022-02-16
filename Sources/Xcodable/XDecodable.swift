
import Foundation

public protocol XDecodable: Decodable {
    init()
}

extension XDecodable {
    
    public init(from decoder: Decoder) throws {
        self.init()
        try decode(from: decoder)
    }
}

extension Decodable {
    
    func decode(from decoder: Decoder) throws {
        var mirror: Mirror? = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror!.children where child.label != nil {
                let wrapper = child.value as? DecodablePropertyWrapper
                try wrapper?.decode(from: decoder, label: child.label!.dropFirst())
            }
            mirror = mirror?.superclassMirror
        }
    }
}


protocol DecodablePropertyWrapper {
    func decode<Label: StringProtocol>(from decoder: Decoder, label: Label) throws
}

extension Decoder {
    
    func decode<T: Decodable>(
        _ stringKeys: [String],
        nestedSymbol: NestedSymbol = .default,
        as type: T.Type = T.self) throws -> T?
    {
        let container = try container(keyedBy: XcodingKey.self)
        return try container.decode(stringKeys, as: type)
    }
    
    func decode<T: Decodable, K: CodingKey>(
        _ codingKeys: [K],
        nestedSymbol: NestedSymbol = .default,
        as type: T.Type = T.self) throws -> T?
    {
        let container = try container(keyedBy: K.self)
        return try container.decode(codingKeys, as: type)
    }
}

extension KeyedDecodingContainer {
    
    func decode<T: Decodable>(
        _ stringKeys: [String],
        nestedSymbol: NestedSymbol = .default,
        as type: T.Type = T.self) throws -> T?
    {
        let codingKeys = stringKeys.compactMap{ Key(stringValue: $0) }
        return try decode(codingKeys, as: type)
    }
    
    func decode<T: Decodable>(
        _ codingKeys: [Self.Key],
        nestedSymbol: NestedSymbol = .default,
        as type: T.Type = T.self) throws -> T?
    {
        if let key = codingKeys.first,
           let value = try decodeNested(key, nestedSymbol: nestedSymbol, as: type)
        {
            return value
        }
        
        let keys = Array(codingKeys.dropFirst())
        
        if keys.isEmpty == false {
            return try decode(keys, as: type)
        }
        
        return nil
    }
    
    func decodeNested<T: Decodable>(
        _ codingKey: Self.Key,
        nestedSymbol: NestedSymbol = .default,
        as type: T.Type = T.self) throws -> T?
    {
        if let value = try decodeValue(codingKey, as: type) {
            return value
        }
        guard
            codingKey.intValue == nil,
            codingKey.stringValue.contains(nestedSymbol)
        else {
            return nil
        }
        let components = codingKey.stringValue.split(separator: nestedSymbol)
        let keys = components.compactMap{ Key(stringValue: String($0)) }
        
        guard
            keys.isEmpty == false,
            let container = nestedContainer(keys.dropLast()),
            let key = keys.last
        else {
            return nil
        }
        let value = try container.decodeNested(
            key,
            nestedSymbol: nestedSymbol,
            as: type
        )
        return value
    }
    
    func nestedContainer(_ keys: [Self.Key]) -> Self? {
        var container: Self? = self
        
        for key in keys {
            container = try? nestedContainer(
                keyedBy: Self.Key,
                forKey: key
            )
            if container == nil {
                return nil
            }
        }
        return container
    }
    
    func decodeValue<T: Decodable>(
        _ codingKey: Self.Key,
        as type: T.Type = T.self) throws -> T?
    {
        var rError: Error?
        
        do {
            if let value = try decodeIfPresent(type, forKey: codingKey) {
                return value
            }
        } catch {
            rError = error
        }
        
        if contains(codingKey) {
            return _decode(codingKey)
        }
        
        if let error = rError {
            throw error
        }
        return nil
    }
    
    func _decode<T: Decodable>(
        _ codingKey: Self.Key,
        as type: T.Type = T.self) -> T?
    {
        if type is Bool.Type || type is Bool?.Type {
            return decodeBool(codingKey) as? T
        }
        
        if type is Int.Type || type is Int?.Type {
            return decodeInt(codingKey) as? T
        }
        
        if type is Int8.Type || type is Int8?.Type {
            return decodeInt8(codingKey) as? T
        }
        
        if type is Int16.Type || type is Int16?.Type {
            return decodeInt16(codingKey) as? T
        }
        
        if type is Int32.Type || type is Int32?.Type {
            return decodeInt32(codingKey) as? T
        }
        
        if type is Int64.Type || type is Int64?.Type {
            return decodeInt64(codingKey) as? T
        }
        
        if type is UInt.Type || type is UInt?.Type {
            return decodeUInt(codingKey) as? T
        }
        
        if type is UInt8.Type || type is UInt8?.Type {
            return decodeUInt8(codingKey) as? T
        }
        
        if type is UInt16.Type || type is UInt16?.Type {
            return decodeUInt16(codingKey) as? T
        }
        
        if type is UInt32.Type || type is UInt32?.Type {
            return decodeUInt32(codingKey) as? T
        }
        
        if type is UInt64.Type || type is UInt64?.Type {
            return decodeUInt64(codingKey) as? T
        }
        
        if type is Double.Type || type is Double?.Type {
            return decodeDouble(codingKey) as? T
        }
        
        if type is Float.Type || type is Float?.Type {
            return decodeFloat(codingKey) as? T
        }
        
        if type is String.Type || type is String?.Type {
            return decodeString(codingKey) as? T
        }
        
        return nil
    }
    
    func decodeBool(_ codingKey: Self.Key) -> Bool? {
        if let intValue = try? decodeIfPresent(Int.self, forKey: codingKey) {
            return intValue != 0
        }
        if let stringValue = try? decodeIfPresent(String.self, forKey: codingKey) {
            switch stringValue.lowercased() {
            case "true", "t", "yes", "y":
                return true
            case "false", "f", "no", "n", "":
                return false
            default:
                if let int = Int(stringValue) {
                    return int != 0
                }
                if let double = Double(stringValue) {
                    return Int(double) != 0
                }
            }
        }
        return nil
    }
    
    func decodeInt(_ codingKey: Self.Key) -> Int? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return bool ? 1 : 0
        }
        
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return Int(double)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return Int(string) ?? 0
        }
        return nil
    }
    
    func decodeInt8(_ codingKey: Self.Key) -> Int8? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return bool ? 1 : 0
        }
        
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return Int8(double)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return Int8(string) ?? 0
        }
        return nil
    }
    
    func decodeInt16(_ codingKey: Self.Key) -> Int16? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return bool ? 1 : 0
        }
        
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return Int16(double)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return Int16(string) ?? 0
        }
        return nil
    }
    
    func decodeInt32(_ codingKey: Self.Key) -> Int32? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return bool ? 1 : 0
        }
        
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return Int32(double)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return Int32(string) ?? 0
        }
        return nil
    }
    
    func decodeInt64(_ codingKey: Self.Key) -> Int64? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return bool ? 1 : 0
        }
        
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return Int64(double)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return Int64(string) ?? 0
        }
        return nil
    }
    
    func decodeUInt(_ codingKey: Self.Key) -> UInt? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return bool ? 1 : 0
        }
        
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return UInt(double)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return UInt(string) ?? 0
        }
        return nil
    }
    
    func decodeUInt8(_ codingKey: Self.Key) -> UInt8? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return bool ? 1 : 0
        }
        
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return UInt8(double)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return UInt8(string) ?? 0
        }
        return nil
    }
    
    func decodeUInt16(_ codingKey: Self.Key) -> UInt16? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return bool ? 1 : 0
        }
        
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return UInt16(double)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return UInt16(string) ?? 0
        }
        return nil
    }
    
    func decodeUInt32(_ codingKey: Self.Key) -> UInt32? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return bool ? 1 : 0
        }
        
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return UInt32(double)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return UInt32(string) ?? 0
        }
        return nil
    }
    
    func decodeUInt64(_ codingKey: Self.Key) -> UInt64? {
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return bool ? 1 : 0
        }
        
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return UInt64(double)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return UInt64(string) ?? 0
        }
        return nil
    }
    
    func decodeDouble(_ codingKey: Self.Key) -> Double? {
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return double
        }
        
        if let int64 = try? decodeIfPresent(Int64.self, forKey: codingKey) {
            return Double(int64)
        }
        
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return Double(string)
        }
        return nil
    }
    
    func decodeFloat(_ codingKey: Self.Key) -> Float? {
        if let float = try? decodeIfPresent(Float.self, forKey: codingKey) {
            return float
        }
        if let int64 = try? decodeIfPresent(Int64.self, forKey: codingKey) {
            return Float(int64)
        }
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return Float(string)
        }
        return nil
    }
    
    func decodeString(_ codingKey: Self.Key) -> String? {
        if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
            return string
        }
        if let bool = try? decodeIfPresent(Bool.self, forKey: codingKey) {
            return String(describing: bool)
        }
        if let int64 = try? decodeIfPresent(Int64.self, forKey: codingKey) {
            return String(describing: int64)
        }
        if let double = try? decodeIfPresent(Double.self, forKey: codingKey) {
            return String(describing: double)
        }
        return nil
    }
}

public extension Decodable {
    
    static func decoded(
        from data: Data,
        using decoder: DataDecoder = JSONDecoder(),
        as type: Self.Type = Self.self) throws -> Self
    {
        return try decoder.decode(type, from: data)
    }
    
    static func decoded(
        from json: [String: Any],
        using decoder: JSONDecoder = JSONDecoder(),
        as type: Self.Type = Self.self,
        options: JSONSerialization.WritingOptions = .fragmentsAllowed) throws -> Self
    {
        let data = try JSONSerialization.data(withJSONObject: json, options: options)
        return try decoder.decode(type, from: data)
    }
    
    static func decoded(
        from array: [Any],
        using decoder: JSONDecoder = JSONDecoder(),
        as type: Self.Type = Self.self,
        options: JSONSerialization.WritingOptions = .fragmentsAllowed) throws -> Self
    {
        let data = try JSONSerialization.data(withJSONObject: array, options: options)
        return try decoder.decode(type, from: data)
    }
    
    static func decoded(
        from string: String,
        using decoder: JSONDecoder = JSONDecoder(),
        as type: Self.Type = Self.self) throws -> Self
    {
        let data = Data(string.utf8)
        return try decoder.decode(type, from: data)
    }
}
