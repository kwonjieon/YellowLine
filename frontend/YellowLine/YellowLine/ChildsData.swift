import Foundation


class ChildsData {
    static func load<T: Codable>(_ filename: String) -> [T] {
        if let file = Bundle.main.path(forResource: filename, ofType: "json") {
//            print(file)
            do {
//                let data = try Data(contentsOf: fileLocation)
                let data = try Data(contentsOf: URL(fileURLWithPath: file))
                let dictData = String(data: data, encoding: .utf8)
                print(dictData)
//                let json = try JSONSerialization.jsonObject(with: data, options: [[]]) as? [[String: Any]]
                return try JSONDecoder().decode([T].self, from: data)
            } catch {
                print("Do but empty")
                return []
            }
        }
        print("Just empty")
        return []
    }
}

