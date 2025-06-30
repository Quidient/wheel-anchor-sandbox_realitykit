//
//  ContentView.swift
//  wheel-anchor-sandbox_realitykit
//
//  Created by Julian Dowell  on 6/18/25.
//

import SwiftUI
import RealityKit
import ARKit
import SceneKit

struct ContentView : View {

    var body: some View {
        ZStack() {
            VStack() {
                tireAnchorPlacementUIView().edgesIgnoringSafeArea(.all)
            }
        }
       
    }

}

#Preview {
    ContentView()
}
