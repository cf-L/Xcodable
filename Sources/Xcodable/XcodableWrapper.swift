
import Foundation

@propertyWrapper public class XcodableWrapper<Value> {

    public typealias Key = String
    public typealias AlternateKey = String

    public var wrappedValue: Value

    var key: Key?
    var alternateKeys: [AlternateKey] = []
    var nestedSymbol: NestedSymbol = .default

    public init(
        wrappedValue: Value,
        key: Key? = nil,
        alternateKeys: [AlternateKey] = [],
        nestedSymbol: NestedSymbol = .default)
    {
        self.wrappedValue = wrappedValue
        self.key = key
        self.alternateKeys = alternateKeys
        self.nestedSymbol = nestedSymbol
    }
}

extension XcodableWrapper: DecodablePropertyWrapper where Value: Decodable {
    
    func decode<Label>(
        from decoder: Decoder,
        label: Label) throws where Label : StringProtocol
    {
        // 如果没有自定义key，则从mirror的label中获取属性名称
        let mainKey = self.key ?? String(label)
        let stringKeys = [mainKey] + alternateKeys
        
        if let value = try decoder.decode(
            stringKeys,
            nestedSymbol: nestedSymbol
            , as: Value.self)
        {
            wrappedValue = value
        }
    }
}

extension XcodableWrapper: EncodablePropertyWrapper where Value: Encodable {
    
    func encode<Label>(
        to encoder: Encoder,
        label: Label) throws where Label : StringProtocol
    {
        let mainKey = self.key ?? String(label)
        try encoder.encode(wrappedValue, for: mainKey, nestedSymbol: nestedSymbol)
    }
}
