//
//  WheelBaseObject.swift
//  wheel-anchor-sandbox_realitykit
//
//  Created by Julian Dowell  on 6/23/25.
//
import RealityKit
import Combine
import SwiftUI

class tireAnchors : Entity, HasModel, HasCollision, HasAnchoring {
    var collisionSubs : [Cancellable] = []
    var transformArray : [Transform] = []
    required init(color: UIColor) {
        super.init()
        self.model = ModelComponent(mesh: .generateSphere(radius: 0.01), materials: [SimpleMaterial(color: .green, isMetallic: false)])
        self.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.01)])
    }
    
    @MainActor @preconcurrency required init() {
        fatalError("init() has not been implemented")
    }
}
