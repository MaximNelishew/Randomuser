import Foundation

protocol GET {
    static func get(_ request: URLRequest, _ completion: @escaping (Data?,URLResponse?,Error?) -> Void)
}

extension GET {
    internal static func get(_ request: URLRequest, _ completion: @escaping (Data?,URLResponse?,Error?) -> Void) {
        DispatchQueue(label: "com.getRequest.dataTask", qos: .background).async {
        URLSession.shared.dataTask(with: request) { (data,resp,error) in
            if let data = data, let status = (resp as? HTTPURLResponse)?.statusCode {
                switch status {
                case (200...299):
                    completion(data,resp,error)
                case 299...: // == error
                    completion(nil,nil,nil)
                // fallthrough // принудительно "проваливается" к следующему кейсу
                default: break
                }
            } else { // NO INTERNET
                completion(nil,nil,nil)
            }
        }.resume()
        }
    }
}
