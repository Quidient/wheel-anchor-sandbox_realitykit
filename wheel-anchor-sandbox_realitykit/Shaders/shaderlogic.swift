//
//  shaderlogic.swift
//  wheel-anchor-sandbox_realitykit
//
//  Created by Julian Dowell  on 6/27/25.
//

import Foundation



private func getShader(from filename: String) -> String {
    do {
        if let dirs = Bundle.main.url(forResource: filename, withExtension: "shader") {
            return try String(contentsOf: dirs, encoding: .utf8)
        }
    } catch {
        print(error)
    }
    print("shader \(filename) not found")
    return ""
}

