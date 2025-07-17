//
//  ElipseGenerator.swift
//  wheel-anchor-sandbox_realitykit
//
//  Created by Julian Dowell  on 6/24/25.
//
import RealityKit
import Foundation
func generateEllipsoidMesh(center: simd_float3, semiAxes: simd_float3, segments: UInt32) -> MeshResource {
    var positions : [SIMD3<Float>] = []
    var normals : [SIMD3<Float>] = []
    var textureCoordinates : [SIMD2<Float>] = []
    var indices : [UInt32] = []
    
    let radiusX = semiAxes.x
    let radiusY = semiAxes.y
    let radiusZ = semiAxes.z
    
  
    for i in 0..<Int(segments) + 1 {
        let phi = Float(i) / Float(segments) * .pi
        for j in 0..<Int(segments) + 1 {
            let theta = Float(j)/Float(segments) * 2 * .pi
            
            let x = radiusX * sin(phi) * cos(theta)
            let y = radiusY * cos(phi)
            let z = radiusZ * sin(phi) * sin(theta)
            let position = SIMD3<Float>(x,y,z) + center
            positions.append(position)
            let normalX = x / radiusX
            let normalY = y / radiusY
            let normalZ = z / radiusZ
            let normalVector = SIMD3<Float>(normalX, normalY, normalZ)
            let magnitude = sqrt(normalVector.x * normalVector.x + normalVector.y * normalVector.y + normalVector.z * normalVector.z)
            let normal: SIMD3<Float>
            if magnitude > 0 {
                normal = SIMD3<Float>(normalVector.x / magnitude, normalVector.y / magnitude, normalVector.z / magnitude)
            }
            else {
                normal = SIMD3<Float>(0, 0, 0)
            }

            normals.append(normal)
            let u = Float(j) / Float(segments)
            let v = Float(i) / Float(segments)
            textureCoordinates.append(SIMD2<Float>(u, v))
        }
    }
    

    for i in 0..<segments {
        for j in 0..<segments {
            let p0 = i * (segments + 1) + j
            let p1 = i * (segments + 1) + (j + 1)
            let p2 = (i + 1) * (segments + 1) + (j + 1)
            let p3 = (i + 1) * (segments + 1) + j
      
            indices.append(p0)
            indices.append(p2)
            indices.append(p1)

            indices.append(p0)
            indices.append(p3)
            indices.append(p2)
        }
    }
    
    
    var descriptor = MeshDescriptor()
    descriptor.positions = MeshBuffer(positions)
    descriptor.normals = MeshBuffer(normals)
    descriptor.textureCoordinates = MeshBuffer(textureCoordinates)
    descriptor.primitives = .triangles(indices)
    
    return try! MeshResource.generate(from: [descriptor])
    
}

public func generateBoxSlab(width: Float, height: Float, depth: Float, cornerRadius: Float = 0.0) -> MeshResource {
    let slabMesh = MeshResource.generateBox(width: width, height: height, depth: depth, cornerRadius: cornerRadius)
    return slabMesh
}


var entities: [Entity] = []
public func  placeEntitiesAroundEllipsoidPerimeter(ellipsoidCenter: SIMD3<Float>, semiAxes: SIMD3<Float>, numberOfEntities: Int, radiusOfEntities: Float, phiForPerimeter: Float) -> [Entity] {
     
    let radiusX = semiAxes.x * 2.5
    let radiusY = semiAxes.y
    let radiusZ = semiAxes.z * 2.5

    
    for i in 0..<numberOfEntities {
        let theta = Float(i) * .pi * 2.0 / Float(numberOfEntities)
        let x = radiusX * sin(phiForPerimeter) * cos(theta)
        let y = radiusY * cos(phiForPerimeter)
        let z = radiusZ * sin(phiForPerimeter) * sin(theta)
        let position = SIMD3<Float>(x, y, z) + ellipsoidCenter
        let entity = ModelEntity( mesh: .generateCylinder(height: 0.05, radius: radiusOfEntities), materials: [SimpleMaterial(color: .red, isMetallic: false)])
        entity.position = position
        entities.append(entity)
    }
    return entities
    
}

