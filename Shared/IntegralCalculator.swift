//
//  IntegralCalculator.swift
//  Overlap-Integrals
//
//  Created by Katelyn Lydeen on 2/14/22.
//

import Foundation
import SwiftUI

class IntegralCalculator: NSObject, ObservableObject {
    @Published var nString = ""
    @Published var rString = ""
    
    @Published var integral1s1sString = ""
    @Published var integral1s2pxString = ""
    @Published var error1s1sString = ""
    @Published var enableButton = true
    
    var n = 1
    var R = 1.0
    var boxXLength = 5.0
    var boxYLength = 5.0
    var boxZLength = 5.0
    var integral1s1s = 0.0
    var integral1s2px = 0.0
    let a0 = 5.2917721090380e-11
    
    func calculateOverlapIntegrals() async {
        (integral1s1s, integral1s2px) = await overlapIntegrals(boundingBoxX: boxXLength, boundingBoxY: boxYLength, boundingBoxZ: boxZLength, R: R, N: n)
        
        // Find the error for the 1s1s integral
        // Add code here.
        
        await updateIntegral1s1sString(text: "\(integral1s1s)")
        await updateIntegral1s2pxString(text: "\(integral1s2px)")
    }
    
    func overlapIntegrals(boundingBoxX: Double, boundingBoxY: Double, boundingBoxZ: Double, R: Double, N: Int) async -> (Double, Double) {
        let myBox = BoundingBox()
        let boxArea = myBox.calculateSurfaceArea(numberOfSides: 6, side1Length: boundingBoxX, side2Length: boundingBoxY, side3Lenth: boundingBoxZ)
        var sum1s1s = 0.0
        var sum1s2px = 0.0
        var calculatedIntegral1s1s = 0.0
        var calculatedIntegral1s2px = 0.0
        
        // Sum over 1 through N
        for _ in stride(from: 1, through: N, by: 1) {
            // Calculate random x, y, and z values inside the bounding box
            let x = 0.0
            let y = 0.0
            let z = 0.0
            
            // Convert the x, y, z values to spherical coordinates for the two wavefunctions
            let r1 = sqrt(pow(x,2) + pow(y,2) + pow(z,2))
            let theta1 = 0.0
            let phi1 = 0.0
            let r2 = 0.0
            let theta2 = 0.0
            let phi2 = 0.0
            
            // Calculate the sums for computing the average
            await sum1s1s += wavefunction1s(r: r1, theta: theta1, phi: phi1) * wavefunction1s(r: r2, theta: theta2, phi: phi2)
            await sum1s2px += wavefunction1s(r: r1, theta: theta1, phi: phi1) * wavefunction2px(r: r2, theta: theta2, phi: phi2)
        }
        calculatedIntegral1s1s = boxArea * sum1s1s/Double(N)
        calculatedIntegral1s2px = boxArea * sum1s2px/Double(N)
        
        return (calculatedIntegral1s1s, calculatedIntegral1s2px)
    }
    
    func wavefunction1s(r: Double, theta: Double, phi: Double) async -> Double {
        let psi = 5.0
        return psi
    }
    
    func wavefunction2px(r: Double, theta: Double, phi: Double) async -> Double {
        let psi = 5.0
        return psi
    }
    
    
    /// updateIntegral1s1sString
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter text: contains the string containing the current value of the integral
    @MainActor func updateIntegral1s1sString(text:String) {
        self.integral1s1sString = text
    }
    
    /// updateIntegral1s2pxString
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter text: contains the string containing the current value of the integral
    @MainActor func updateIntegral1s2pxString(text:String) {
        self.integral1s2pxString = text
    }
    
    /// setButton Enable
    /// Toggles the state of the Enable Button on the Main Thread
    /// - Parameter state: Boolean describing whether the button should be enabled.
    @MainActor func setButtonEnable(state: Bool) {
        if state {
            Task.init {
                await MainActor.run {
                    self.enableButton = true
                }
            }
        }
        else{
            Task.init {
                await MainActor.run {
                    self.enableButton = false
                }
            }
                
        }
        
    }
}
