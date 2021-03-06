//
//  SwiftKit+Environment.swift
//  SwiftKit
//
//  Created by Sven Tiigi on 01.05.19.
//

import Foundation

// MARK: - Environment

public extension SwiftKit {
    
    /// The Environment
    enum Environment: String, Codable, Equatable, Hashable, CaseIterable {
        /// The Production Environment
        case production
        /// The Development Environment
        case development
        /// The Test Environment
        case test
    }
    
}
