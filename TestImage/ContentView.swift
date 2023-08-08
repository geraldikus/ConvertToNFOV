//
//  ContentView.swift
//  TestImage
//
//  Created by Anton on 07.08.23.
//

import SwiftUI
import CoreImage
import CoreGraphics
import Accelerate

class E2P {
    private let frame: UIImage
    private let equ_w: Int
    private let equ_h: Int
    private let focus_of_view: Double 
    private let width: Int
    private let height: Int
    private let wFOV: CGFloat
    private let hFOV: CGFloat
   

    
    
    init(originalImage: UIImage, fov: Double) {
        self.frame = originalImage
        self.equ_w = Int(originalImage.size.width)
        self.equ_h = Int(originalImage.size.height)
        self.focus_of_view = fov
        self.width = 1400
        self.height = 1400
        self.wFOV = CGFloat(fov) // Set the FOV for wFOV
        self.hFOV = CGFloat(self.height) / CGFloat(self.width) * wFOV
       

    }

    private func combinedMatrix() -> [[CGPoint]] {
        var points = [[CGPoint]]()
        
        for row in 0..<height {
            var rowPoints = [CGPoint]()
            for col in 0..<width {
                let x = CGFloat(col) / CGFloat(width) * 2 - 1
                let y = CGFloat(row) / CGFloat(height) * 2 - 1
                rowPoints.append(CGPoint(x: x, y: y))
            }
            points.append(rowPoints)
        }
        
        return points
    }


    
    private func bilinearInterpolationForPointPair(point: CGPoint) -> CGPoint {
        var x = point.x
        var y = point.y
        let combined = self.combinedMatrix()
        
        var minSum: CGFloat = CGFloat.greatestFiniteMagnitude
        var resultPoint: CGPoint?
        
        for row in 0..<combined.count {
            for col in 0..<combined[row].count {
                let p = combined[row][col]
                let sum = pow(p.x, 2) + pow(p.y, 2)
                if sum < minSum {
                    minSum = sum
                    resultPoint = p
                }
            }
        }
        
        if let resultPoint = resultPoint {
            x = resultPoint.x
            y = resultPoint.y
        }
        
        return CGPoint(x: x, y: y)
    }

    private func bilinearInterpolationMatrix(lon: Double, lat: Double) -> [[CGPoint]] {
        let ufXCoords = lon
        let vfYCoords = lat
        
        var xxDense = [CGFloat](repeating: 0.0, count: width * height)
        var yyDense = [CGFloat](repeating: 0.0, count: width * height)
        
        var combinedMatrix = [[CGPoint]](repeating: [CGPoint](repeating: CGPoint.zero, count: width), count: height)
        
        for y in 0..<equ_h {
            for x in 0..<equ_w {
                let index = y * width + x
                
                xxDense[index] = CGFloat(ufXCoords)
                yyDense[index] = CGFloat(vfYCoords)
                
                combinedMatrix[y][x] = CGPoint(x: xxDense[index], y: yyDense[index])
            }
        }
        
        return combinedMatrix
    }

    private func convertFOVToOriginalCoordinates(x: Int, y: Int) -> CGPoint {
        guard y >= 0 && y < height && x >= 0 && x < width else {
            return .zero // Handle out-of-bounds indices
        }
        return combinedMatrix()[y][x]
    }
    
    
    private func convertOriginalToFOVCoordinates(x: Int, y: Int) -> CGPoint {
        guard y >= 0 && y < height && x >= 0 && x < width else {
            return .zero
        }
        
        var point = CGPoint(x: CGFloat(x), y: CGFloat(y))
        point = bilinearInterpolationForPointPair(point: point)
        
        print("convertOriginalToFOVCoordinates - Before combinedMatrix()")
        let combined = combinedMatrix()
        print("convertOriginalToFOVCoordinates - After combinedMatrix()")
        
        return CGPoint(x: point.x, y: point.y)
    }


    
    func toNFOV(theta: Double, phi: Double) -> UIImage? {
        print("toNFOV: theta = \(theta), phi = \(phi)")
        
        guard let originalCGImage = frame.cgImage else {
            print("toNFOV: Failed to get CGImage from frame")
            return nil
        }
        
        let equ_h = originalCGImage.height
        let equ_w = originalCGImage.width
        let equ_cx = CGFloat((equ_w - 1) / 2)
        let equ_cy = CGFloat((equ_h - 1) / 2)
        
        var outImage: UIImage?
        
        if let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * width,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) {
            context.interpolationQuality = .high
            
            for y in 0..<equ_h {
                for x in 0..<equ_w {
                    let originalCoordinates = convertOriginalToFOVCoordinates(x: x, y: y)
                    let (r, g, b) = interpolateColor(lon: originalCoordinates.x, lat: originalCoordinates.y)
                    
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
        print("to_perspective: theta = \(theta), phi = \(phi)")
        
        guard let originalCGImage = frame.cgImage else {
            print("to_perspective: Failed to get CGImage from frame")
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
        // Normalize lon and lat to [0, 1] range
        let lonNormalized = (lon + 180.0) / 360.0
        let latNormalized = (lat + 90.0) / 180.0
        
        // Interpolate color components based on normalized lon and lat
        let red = lonNormalized
        let green = latNormalized
        let blue = 0.5
        
        return (red, green, blue)
    }


}

struct ContentView: View {
    @State private var originalImage: UIImage?
    @State private var nfovImage: UIImage?
    let imageName = "panorama1" // Replace with your image name
    
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
                    let e2p = E2P(originalImage: originalImage, fov: 120)
                    nfovImage = e2p.toNFOV(theta: 0, phi: 0)
                } else {
                    print("somethin wrong")
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

extension Array where Element == CGPoint {
    func reshape(height: Int, width: Int, channels: Int) -> [[CGPoint]] {
        var reshapedArray = [[CGPoint]]()
        
        var currentIndex = 0
        for _ in 0..<height {
            var row = [CGPoint]()
            for _ in 0..<width {
                row.append(self[currentIndex])
                currentIndex += channels
            }
            reshapedArray.append(row)
        }
        
        return reshapedArray
    }
}







