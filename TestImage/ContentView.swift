//
//  ContentView.swift
//  TestImage
//
//  Created by Anton on 07.08.23.
//

import SwiftUI
import CoreImage
import CoreGraphics

class E2P {
    private let frame: UIImage
    private let equ_w: Int
    private let equ_h: Int
    private let focus_of_view: Double // Add this property
    private let width: Int // Add this property
    private let height: Int // Add this property
    private let wFOV: CGFloat // Add this property
    private let hFOV: CGFloat // Add this property
    
    init(originalImage: UIImage, fov: Double) {
        self.frame = originalImage
        self.equ_w = Int(originalImage.size.width)
        self.equ_h = Int(originalImage.size.height)
        self.focus_of_view = fov
        self.width = 1600 // Set your desired width
        self.height = 1600 // Set your desired height
        self.wFOV = CGFloat(fov) // Set the FOV for wFOV
        self.hFOV = CGFloat(self.height) / CGFloat(self.width) * wFOV
        // Set other properties and initialization logic here
    }
    
    func to_nfov(theta: Double, phi: Double) -> UIImage? {
        guard let originalCGImage = frame.cgImage else {
            return nil
        }
        
        let equ_h = originalCGImage.height
        let equ_w = originalCGImage.width
        let equ_cx = CGFloat((equ_w - 1) / 2)
        let equ_cy = CGFloat((equ_h - 1) / 2)
        
        let wFOV: CGFloat = CGFloat(self.focus_of_view)
        let hFOV = CGFloat(self.height) / CGFloat(self.width) * wFOV
        let c_x = CGFloat((self.width - 1) / 2)
        let c_y = CGFloat((self.height - 1) / 2)
        let wangle = (180 - wFOV) / 2.0
        // ... (continue with the rest of the variables)

        var outImage: UIImage?
        
        if let context = CGContext(
                data: nil,
                width: equ_w,
                height: equ_h,
                bitsPerComponent: 8,
                bytesPerRow: 4 * equ_w,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) {
                context.interpolationQuality = .high
                
                for y in 0..<equ_h {
                    for x in 0..<equ_w {
                        let lon = Double(x) / Double(equ_w) * 360.0 - 180.0
                        let lat = -Double(y) / Double(equ_h) * 180.0 + 90.0
                        
                        let (r, g, b) = interpolateColor(lon: lon, lat: lat) // Implement this function
                        
                        context.setFillColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
                        context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                    }
                }
                
                if let cgImage = context.makeImage() {
                    outImage = UIImage(cgImage: cgImage)
                }
            }
        return outImage
    }
    
    func to_perspective(theta: Double, phi: Double) -> UIImage? {
            guard let originalCGImage = frame.cgImage else {
                return nil
            }

            let equ_h = originalCGImage.height
            let equ_w = originalCGImage.width

            // Calculate pFOV and p_hFOV based on width and height
            let pFOV: CGFloat = CGFloat(self.focus_of_view)
            let p_hFOV = CGFloat(self.height) / CGFloat(self.width) * pFOV

            var outImage: UIImage?

            if let context = CGContext(
                data: nil,
                width: equ_w,
                height: equ_h,
                bitsPerComponent: 8,
                bytesPerRow: 4 * equ_w,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) {
                context.interpolationQuality = .high

                for y in 0..<equ_h {
                    for x in 0..<equ_w {
                        let p_x = CGFloat(x)
                        let p_y = CGFloat(y)

                        // Calculate lon and lat based on p_x and p_y using inverse transformations
                        let lon = (p_x / CGFloat(equ_w)) * 360.0 - 180.0
                        let lat = -(p_y / CGFloat(equ_h)) * 180.0 + 90.0

                        // Apply inverse transformations to get original theta and phi
                        let lon_normalized = (lon + 180.0) / 360.0
                        let lat_normalized = (-lat + 90.0) / 180.0
                        let original_theta = (lon_normalized - 0.5) * CGFloat(wFOV) + 0.5 * CGFloat(wFOV)
                        let original_phi = -((lat_normalized - 0.5) * CGFloat(hFOV)) + 0.5 * CGFloat(hFOV)

                        let (r, g, b) = interpolateColor(lon: original_theta, lat: original_phi) // Implement this function

                        context.setFillColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
                        context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                    }
                }

                if let cgImage = context.makeImage() {
                    outImage = UIImage(cgImage: cgImage)
                }
            }

            return outImage
        }



    func interpolateColor(lon: Double, lat: Double) -> (Double, Double, Double) {
        // Implement your color interpolation logic here based on lon and lat
          return (lon / 360.0, lat / 180.0, 0.5)
        //return (0, 0, 0)
    }

}

struct ContentView: View {
    @State private var originalImage: UIImage?
    @State private var nfovImage: UIImage?
    let imageName = "ggg" // Replace with your image name
    
    var body: some View {
        VStack {
            if let originalImage = originalImage {
                Image(uiImage: originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

            if let nfovImage = nfovImage {
                Image(uiImage: nfovImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

            Button("Convert to NFOV") {
                if let originalImage = UIImage(named: imageName) {
                    let e2p = E2P(originalImage: originalImage, fov: 120) // Set the desired FOV
                    // You need to implement the 'to_nfov' function to return the converted image
                    nfovImage = e2p.to_nfov(theta: 0, phi: 0) // Set the desired theta and phi angles
                }
            }
            Button("Convert to Perspective") {
                if let originalImage = UIImage(named: imageName) {
                    let e2p = E2P(originalImage: originalImage, fov: 120) // Set the desired FOV
                    nfovImage = e2p.to_perspective(theta: 0, phi: 0) // Set the desired theta and phi angles
                }
            }

        }
        .onAppear {
            if let image = UIImage(named: imageName) {
                originalImage = image
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

