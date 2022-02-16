    import XCTest
    @testable import Xcodable
    
    class Model: Xcodable {
        @XcodableWrapper(key: "info.name", alternateKeys: ["N_name"])
        var name: String? = nil
        @XcodableWrapper
        var age: Int = 0
        
        required init() {
            
        }
    }
    
    final class XcodableTests: XCTestCase {
        func testExample() {
            let dic: [String: Any] = [
                "N_name": "eden",
                "age": 27
            ]
            if let model = try? Model.decoded(from: dic) {
                XCTAssertEqual(model.name, "eden")
                XCTAssertEqual(model.age, 27)
            } else {
                XCTFail()
            }
        }
    }
