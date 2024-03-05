//
//  LocalStorageService.swift
//  PulsePomodoro Watch App
//
//  Created by Mateus Henrique on 05/03/24.
//

import Foundation

class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    func save(key: String, value: Any) {
        defaults.set(value, forKey: key)
    }
    
    func get(key: String) -> Any? {
        return defaults.value(forKey: key)
    }
}
