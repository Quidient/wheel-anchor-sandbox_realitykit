//
//  ARSessionCoordinator.swift
//  wheel-anchor-sandbox_realitykit
//
//  Created by Julian Dowell  on 6/18/25.
//
import SwiftUI
import RealityKit
import ARKit
import Combine
import Foundation
//MARK: - CustomTirePlacementAnchors
var tireAnchorCount = 0
var statePlacingOrStepping : Bool = false
class ARSessionInfo: ObservableObject {
    @Published var anchorCount: Int = 0 // Our integer output
}

// MARK: - AnchorPlacementClass
class AnchorPlacementClass: NSObject, ObservableObject {
    weak var arView: ARView?

    private var temporarySphere: Entity?

    private var lastHitTransform: Transform?
    private var tireAnchorCount : Int = 0
    var transformArray : [Transform] = []
    @Published var showConfirmationUI: Bool = false
    
    public var cancellables = Set<AnyCancellable>()
    private var didAddEntitySubscription: Cancellable?
    override init() {
        super.init()
    }

    /// Sets the ARView instance for the recasting class.
    func setARView(_ arView: ARView) {
        self.arView = arView
        setupAnchorEventSubscription()
    }
    //MARK: - Anchor Placement Lifecycle tracking
    private func setupTemporarySphere() {
        guard temporarySphere == nil else { return }
        guard let arView = arView else { return }

        temporarySphere = tireAnchors(color: .green)
        let tireAnchorSub = arView.scene.subscribe(to: SceneEvents.AnchoredStateChanged.self, on: temporarySphere) { event in
            if event.isAnchored {
                 //Our Anchor is
           
                print("Tire Anchor is placed")
            } else {
                
            }
        }
        if let sphere = temporarySphere {
            
            let anchor = AnchorEntity()
            anchor.addChild(sphere)
            arView.scene.addAnchor(anchor)
            sphere.isEnabled = false // Start disabled until first hit from a tap
            let entity = tireAnchors(color: .green)
        }
    }

    /// Removes the temporary sphere from the AR scene and resets state.
    private func removeTemporarySphere() {
        temporarySphere?.removeFromParent()
        temporarySphere = nil
        lastHitTransform = nil // Clear the stored transform
        showConfirmationUI = false // Hide UI when sphere is removed
    }

   
    func performTapRaycast(at screenPoint: CGPoint, in arView: ARView) {
        // Ensure temporary sphere is set up
        if temporarySphere == nil {
            setupTemporarySphere()
        }

   
        let results = arView.raycast(from: screenPoint, allowing: .estimatedPlane, alignment: .any)

        if let result = results.first {
           

            let hitTransform = Transform(matrix: result.worldTransform)

            self.lastHitTransform = hitTransform
            
            temporarySphere?.setTransformMatrix(hitTransform.matrix, relativeTo: nil) // Set world transform
            temporarySphere?.isEnabled = true // Enable visibility

            // Show confirmation UI after a successful tap
            showConfirmationUI = true
            print("Temporary sphere placed. Ready for confirmation.")
        } else {
            
            removeTemporarySphere()
            print("No surface found at tap location. Placement cancelled.")
        }
    }

    
    func placeAnchor() {
        guard let arView = arView, let transform = lastHitTransform else {
            print("No valid tap raycast result to place anchor.")
            return
        }
        transformArray.append(transform)
        let anchorEntity = AnchorEntity()
        anchorEntity.transform = transform
        let tireAnchorEntity = tireAnchors(color: .green)
        tireAnchorEntity.name = "t" + "\(tireAnchorCount)"
        tireAnchorEntity.transform = lastHitTransform!
        anchorEntity.addChild(tireAnchorEntity)
        arView.scene.addAnchor(anchorEntity)
        tireAnchorCount += 1
        removeTemporarySphere()
    }
    private func setupAnchorEventSubscription() {
        guard let arView = arView else { return }

        didAddEntitySubscription = arView.scene.subscribe(to: SceneEvents.AnchoredStateChanged.self) { event in
              
              let tireAnchor = event.anchor
       
             if tireAnchor.isAnchored && tireAnchor.name == "t3" {
                 self.generateElipsoid()
                 statePlacingOrStepping.toggle()
              } else {
               
              }
          }
      }
    func generateSphere(position: SIMD3<Float>) {
        guard let arView = arView else { return }
        let sphere = MeshResource.generateSphere(radius: 0.01)
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        let entity = ModelEntity(mesh: sphere, materials: [material])
        entity.position = simd_float3(position)
        arView.scene.addAnchor(AnchorEntity(world: position))
         
    }
    func generateElipsoid() {
   
        guard let arView = arView else { return }
       
    
       let p1 = self.transformArray[0].translation
       let p2 = self.transformArray[1].translation
       let p3 = self.transformArray[2].translation
       let p4 = self.transformArray[3].translation
           
           
           let cX = (p1.x + p2.x + p3.x + p4.x) / 4.0
           let cY = (p1.y + p2.y + p3.y + p4.y) / 4.0
           let cZ = (p1.z + p2.z + p3.z + p4.z) / 4.0
           let cPoint = SIMD3<Float>(cX, cY, cZ)
           
           
           let vAB = p2 - p1
           let vAC = p3 - p1
           
           
           let nmV = cross(vAB, vAC)
           
           
           if length(nmV) < 1e-6 {
               fatalError("Error: The provided points are nearly collinear, cannot define a unique plane.")
           }
           
           
           let nmlV = normalize(nmV)
           
           
           let A = nmlV.x
           let B = nmlV.y
           let C = nmlV.z
           
           
           let D = -(dot(nmlV, p1))
                
           let centerAnchor = AnchorEntity(world: cPoint)
           
           
           let w = distance(p1, p2)
           let h = distance(p2, p3)
           
           
           let planeMesh = MeshResource.generatePlane(width: w, height: h, cornerRadius: 0.05)
           let planeMaterial = SimpleMaterial(color: .blue, isMetallic: true)
           let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
           
           let defaultPlaneNormal = SIMD3<Float>(0, 1, 0) //
          let rotationQuaternion = simd_quaternion(defaultPlaneNormal, nmlV)
           planeEntity.orientation = rotationQuaternion
           
        
           let circleRadius = min(w, h) * 0.4
           let elipse = MeshResource.generateCylinder(height: (h/20), radius: (circleRadius/10))
           let elipseEntity = ModelEntity(mesh: elipse, materials: [SimpleMaterial(color: .red, isMetallic: false)])
           
           elipseEntity.orientation = rotationQuaternion
  
           elipseEntity.position = SIMD3<Float>(0, 0.001, 0)
           
           centerAnchor.addChild(elipseEntity)
        
           let ellipsoidSemiAxes = SIMD3<Float>(x: 2, y: 1.4, z: 2)
            let segments: UInt32 = 40

              // Generate the ellipsoid mesh
              let ellipsoidMesh = generateEllipsoidMesh(
                  center: elipseEntity.position,
                  semiAxes: ellipsoidSemiAxes,
                  segments: segments
              )

              // Create a material for the ellipsoid
              let material = SimpleMaterial(color: .systemPink.withAlphaComponent(0.3), isMetallic: false)

              // Create a model entity with the mesh and material
              let ellipsoidEntity = ModelEntity(mesh: ellipsoidMesh, materials: [material])
              ellipsoidEntity.generateCollisionShapes(recursive: true) // For interaction
              centerAnchor.addChild(ellipsoidEntity)
             
            
           let steppingStoneArray =  placeEntitiesAroundEllipsoidPerimeter(ellipsoidCenter: elipseEntity.position, semiAxes: ellipsoidSemiAxes, numberOfEntities: 15, radiusOfEntities: 0.2, phiForPerimeter: .pi/1.2)
           //Update so that the anchor is a new anchor, grab the position once they've been instantiatied
           for entity in steppingStoneArray {
               entity.generateCollisionShapes(recursive: true)
               print("Current Entity Position: \(entity.position)")
               centerAnchor.addChild(entity)
             
           }
             //  arView.scene.addAnchor(eliposidAnchor)
        arView.scene.addAnchor(centerAnchor)
    }
    func cancelPlacement() {
        print("Placement cancelled.")
        removeTemporarySphere()
        
    }
}

// MARK: - ARViewRepresentable

/// A SwiftUI ViewRepresentable that wraps ARView and integrates with RecastingClass.
struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var anchorPlacementHandler: AnchorPlacementClass
    @EnvironmentObject var arSessionInfo: ARSessionInfo
    @State private var updateSubscription: Cancellable?
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        
        anchorPlacementHandler.setARView(arView)
       

   
     
        // Add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // No continuous updates needed here for raycasting
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(anchorPlacement: anchorPlacementHandler)
    }

    // MARK: - Coordinator
   
    class Coordinator: NSObject, ARSessionDelegate {
        var anchorPlacementClass: AnchorPlacementClass

        init(anchorPlacement: AnchorPlacementClass) {
            self.anchorPlacementClass = anchorPlacement
        }
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
        }
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = sender.view as? ARView else { return }
            let tapLocation = sender.location(in: arView)
            
          anchorPlacementClass.performTapRaycast(at: tapLocation, in: arView)
        }
    }
}



struct SimpleCardView: View {
    enum HorizontalAlignmentPosition {
        case leading
        case trailing
    }

    let text: String
    var backgroundColor: Color = .blue
    var textColor: Color = .white
    var cornerRadius: CGFloat = 10
    var padding: CGFloat = 20
    var shadowRadius: CGFloat = 5
    var shadowX: CGFloat = 0
    var shadowY: CGFloat = 3
    var horizontalAlignment: HorizontalAlignmentPosition = .leading

    var body: some View {
        HStack {
            if horizontalAlignment == .trailing {
                Spacer()
            }

            ZStack {
        
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor).opacity(0.7)
                    .shadow(radius: shadowRadius, x: shadowX, y: shadowY)

              
                Text(text)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .padding(padding)
                    .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7)

            if horizontalAlignment == .leading {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct tireAnchorPlacementUIView: View {
    @StateObject private var tireAnchorPlacementHandler = AnchorPlacementClass()
    @State private var instructionText = "Locate your tire and tap to place the green dot in the center of the wheelbase."
    var body: some View {
        ZStack {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
                .environmentObject(tireAnchorPlacementHandler)
            
         
            VStack {
                VStack() {
                  
                    SimpleCardView(
                        text: instructionText,
                        backgroundColor: .green,
                        textColor: .white,
                        cornerRadius: 8,
                        padding: 25,
                        shadowRadius: 6,
                        shadowY: 5,
                        horizontalAlignment: .leading
                    ).onChange(of: statePlacingOrStepping) { newValue in
                        instructionText = "Walk to Each Stepping Stone to Capture your Car"
                    }
                }.offset(y: 70)
                Spacer()
                
                if tireAnchorPlacementHandler.showConfirmationUI {
                   
                    HStack(spacing: 100) {
                   
                        Button(action: {
                            tireAnchorPlacementHandler.cancelPlacement()
                        }) {
                         VStack() {
                             Text("Retry Placement").font(.custom("Helvetica-Bold", size: 14)).foregroundColor(.black)
                             Image(systemName: "xmark.circle.fill")
                                 .resizable()
                                 .frame(width: 60, height: 60)
                                 .foregroundColor(.red)
                                 .background(Color.white.opacity(0.8))
                                 .clipShape(Circle())
                            }
                           
                        }

                        
                        Button(action: {
                            tireAnchorPlacementHandler.placeAnchor()
                        }) {
                            VStack() {
                                Text("Confirm Placement").font(.custom("Helvetica-Bold", size: 14)).foregroundColor(.black)
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.green)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                        
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        tireAnchorPlacementUIView()
    }
}
func generateGuidedPathFromCentralAnchor(center: SIMD3<Float>, semiMajor: Float, semiMinor: Float, steppingStonesCount: Int, yPos: Float) -> [SIMD3<Float>] {
    var points: [SIMD3<Float>] = []
    let angleIncrement = (2 * Float.pi) / Float(steppingStonesCount)
    for steppingStone in 0...(steppingStonesCount - 1) {
        let angle = Float(steppingStone) * angleIncrement
        
        let x = semiMajor * cos(angle)
        let z = semiMinor * sin(angle)
        let point = SIMD3<Float>(center.x + x, yPos, center.z + z)
        points.append(point)
        
    }
    return points
}
func createPlaneElipseEntity(from transforms: [Transform]) -> AnchorEntity? {
    
    guard transforms.count >= 4 else {
        print("Error: Expected at least 4 transforms to define a rectangle.")
        return nil
    }
    
    
    let p1 = transforms[0].translation
    let p2 = transforms[1].translation
    let p3 = transforms[2].translation
    let p4 = transforms[3].translation
    
    
    let cX = (p1.x + p2.x + p3.x + p4.x) / 4.0
    let cY = (p1.y + p2.y + p3.y + p4.y) / 4.0
    let cZ = (p1.z + p2.z + p3.z + p4.z) / 4.0
    let cPoint = SIMD3<Float>(cX, cY, cZ)
    
    
    let vAB = p2 - p1
    let vAC = p3 - p1
    
    
    let nmV = cross(vAB, vAC)
    
    
    if length(nmV) < 1e-6 {
        print("Error: The provided points are nearly collinear, cannot define a unique plane.")
        return nil
    }
    
    
    let nmlV = normalize(nmV)
    
    
    let A = nmlV.x
    let B = nmlV.y
    let C = nmlV.z
    
    
    let D = -(dot(nmlV, p1))
    let centerAnchor = AnchorEntity(world: cPoint)
    
    
    let w = distance(p1, p2)
    let h = distance(p2, p3)
    
    

   let defaultPlaneNormal = SIMD3<Float>(0, 1, 0)
   let rotationQuaternion = simd_quaternion(defaultPlaneNormal, nmlV)

    
    let circleRadius = min(w, h) * 0.4
    let elipse = MeshResource.generateCylinder(height: h, radius: circleRadius)
    let elipseEntity = ModelEntity(mesh: elipse, materials: [SimpleMaterial(color: .red, isMetallic: false)])
    
    elipseEntity.orientation = rotationQuaternion
    elipseEntity.position = SIMD3<Float>(0, 0.001, 0)
    
    centerAnchor.addChild(elipseEntity)
    
    return centerAnchor

     
   
}
