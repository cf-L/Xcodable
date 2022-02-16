
import Foundation

public protocol XEncodable: Encodable { }

extension XEncodable {
    
    public func encode(to encoder: Encoder) throws {
        var mirror: Mirror? = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror!.children where child.label != nil {
                let wrapper = child.value as? EncodablePropertyWrapper
                try wrapper?.encode(to: encoder, label: child.label!.dropFirst())
            }
            mirror = mirror?.superclassMirror
        }
    }
}

protocol EncodablePropertyWrapper {
    func encode<Label: StringProtocol>(to encoder: Encoder, label: Label) throws
}

extension Encoder {
    
    func encode<T: Encodable>(
        _ value: T?,
        for stringKey: String,
        nestedSymbol: NestedSymbol = .default) throws
    {
        let key = XcodingKey(stringKey)
        try encode(value, for: key)
    }
    
    func encode<T: Encodable, K: CodingKey>(
        _ value: T?,
        for codingKey: K,
        nestedSymbol: NestedSymbol = .default) throws
    {
        try _encode(value, for: codingKey, nestedSymbol: nestedSymbol)
    }
    
    private func _encode<T: Encodable, K: CodingKey>(
        _ value: T?,
        for codingKey: K,
        nestedSymbol: NestedSymbol = .default) throws
    {
        let stringValue = codingKey.stringValue
        
        if stringValue.contains(nestedSymbol), stringValue.count > 1 {
            try _encodeNested(value, for: codingKey)
        } else {
            try _encodeValue(value, for: codingKey)
        }
    }
    
    private func _encodeValue<T: Encodable, K: CodingKey>(
        _ value: T?,
        for codingKey: K) throws
    {
        var container = self.container(keyedBy: K.self)
        try container.encodeIfPresent(value, forKey: codingKey)
    }
    
    private func _encodeNested<T: Encodable, K: CodingKey>(
        _ value: T?,
        for codingKey: K,
        nestedSymbol: NestedSymbol = .default) throws
    {
        let components = codingKey.stringValue.split(separator: nestedSymbol)
        let keys = components.compactMap{ K(stringValue: String($0)) }
        
        var container = self.container(keyedBy: K.self)
        
        for key in keys.dropLast() {
            container = container.nestedContainer(keyedBy: K.self, forKey: key)
        }
        
        if let codingKey = keys.last {
            try container.encodeIfPresent(value, forKey: codingKey)
        }
    }
}

public extension Encodable {
    
    func encoded(using encoder: DataEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(self)
    }
    
    func encoded(
        using encoder: JSONEncoder = JSONEncoder(),
        options: JSONSerialization.ReadingOptions = .fragmentsAllowed) throws -> [String: Any]?
    {
        let data = try encoded(using: encoder) as Data
        return try JSONSerialization.jsonObject(with: data, options: options) as? [String: Any]
    }
    
    func encoded(
        using encoder: JSONEncoder = JSONEncoder(),
        options: JSONSerialization.ReadingOptions = .fragmentsAllowed) throws -> [Any]?
    {
        let data = try encoded(using: encoder) as Data
        return try JSONSerialization.jsonObject(with: data, options: options) as? [Any]
    }
    
    func encoded(
        using encoder: JSONEncoder = JSONEncoder(),
        encoding: String.Encoding = .utf8) throws -> String?
    {
        let data = try encoded(using: encoder) as Data
        return String(data: data, encoding: encoding)
    }
}
