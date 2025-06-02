import Foundation

extension UserDefaults {
    func atomicUpdate(forKey key: String, transform: (Any?) -> Any?) {
        synchronize() // Ensure we have latest value
        let currentValue = object(forKey: key)
        let newValue = transform(currentValue)
        if let new = newValue {
            set(new, forKey: key)
        } else {
            removeObject(forKey: key)
        }
        synchronize() // Ensure changes are written
    }
}
