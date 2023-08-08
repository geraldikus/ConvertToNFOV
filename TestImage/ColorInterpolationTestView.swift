//
//  ColorInterpolationTestView.swift
//  TestImage
//
//  Created by Anton on 08.08.23.
//

import SwiftUI

struct ColorInterpolationTestView: View {
    
    let image = UIImage(named: "ggg")
    var e2p: E2P
    
    init() {
            e2p = E2P(originalImage: image!, fov: 0)
        }
    
    var body: some View {
        VStack {
            ForEach(0..<360) { lon in
                HStack {
                    ForEach(0..<180) { lat in
                        let (r, g, b) = e2p.interpolateColor(lon: Double(lon), lat: Double(lat))
                        Color(red: r, green: g, blue: b)
                            .frame(width: 2, height: 2)
                    }
                }
            }
        }
    }
}

struct ColorInterpolationTestView_Previews: PreviewProvider {
    static var previews: some View {
        ColorInterpolationTestView()
    }
}

