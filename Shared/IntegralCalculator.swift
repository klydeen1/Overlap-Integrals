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
    var boxXLength = 10.0
    var boxYLength = 5.0
    var boxZLength = 5.0
    var integral1s1s = 0.0
    var integral1s2px = 0.0
    var error1s1s = 0.0
    let a0 = 5.2917721090380e-11
    
    /// calculateOverlapIntegrals
    /// Runs the function to calculate the overlap integrals and updates the results
    func calculateOverlapIntegrals() async {
        (integral1s1s, error1s1s, integral1s2px) = await overlapIntegrals(boundingBoxX: boxXLength, boundingBoxY: boxYLength, boundingBoxZ: boxZLength, R: R, N: n)
        
        await updateIntegral1s1sString(text: "\(integral1s1s)")
        await updateError1s1sString(text: "\(error1s1s)")
        await updateIntegral1s2pxString(text: "\(integral1s2px)")
    }
    
    /// overlapIntegrals
    /// - Parameters:
    ///   - boundingBoxX: the length of the bounding box in the x-direction
    ///   - boundingBoxY: the length of the bounding box in the y-direction
    ///   - boundingBoxZ: the length of the bounding box in the z-direction
    ///   - R: the interatomic spacing between the orbitals in units of Bohr length a0
    ///   - N: the number of iterations for computing the integrals
    /// - returns: a 3-tuple containing the overlap integral of the 1s-1s orbitals, the error in the 1s-1s integral, and the overlap integral of the 1s-2px orbitals
    func overlapIntegrals(boundingBoxX: Double, boundingBoxY: Double, boundingBoxZ: Double, R: Double, N: Int) async -> (Double, Double, Double) {
        let myBox = BoundingBox()
        let boxArea = myBox.calculateSurfaceArea(numberOfSides: 6, side1Length: boundingBoxX, side2Length: boundingBoxY, side3Lenth: boundingBoxZ)
        var sum1s1s = 0.0
        var sum1s2px = 0.0
        var calculatedIntegral1s1s = 0.0
        var calculatedIntegral1s2px = 0.0
        
        // Sum over 1 through N
        for _ in stride(from: 1, through: N, by: 1) {
            // Calculate random x, y, and z values inside the bounding box
            // The box itself is centered on (R/2,0,0)
            let x = Double.random(in: ((R-boundingBoxX)/2)...((R+boundingBoxX)/2))
            let y = Double.random(in: (-boundingBoxY/2)...(boundingBoxY/2))
            let z = Double.random(in: (-boundingBoxZ/2)...(boundingBoxZ/2))
            
            // Convert the x, y, z values to spherical coordinates for the two wavefunctions
            // The first wavefunction will be located at the origin and the second will be at (R,0,0)
            let r1 = sqrt(pow(x,2) + pow(y,2) + pow(z,2))
            let theta1 = atan(y/x)
            let phi1 = atan(sqrt(pow(x,2) + pow(y,2))/z)
            let r2 = sqrt(pow((x-R),2) + pow(y,2) + pow(z,2))
            let theta2 = atan(y/(x-R))
            let phi2 = atan(sqrt(pow((x-R),2) + pow(y,2))/z)
            
            // Calculate the sums for computing the average
            await sum1s1s += wavefunction1s(r: r1) * wavefunction1s(r: r2)
            await sum1s2px += wavefunction2px(r: r1, theta: theta1, phi: phi1) * wavefunction1s(r: r2)
        }
        // Multiply the sums by approproate constants
        sum1s1s *= 1/Double.pi//*pow(R,3))
        sum1s2px *= 1/(32*Double.pi)//*pow(R,3)
        // Calculate the integrals by multiplying the average function value by the bounding box area
        calculatedIntegral1s1s = boxArea * sum1s1s/Double(N)
        let error1s1s = await calculate1s1sError(R: R, numericalIntegral: calculatedIntegral1s1s)
        calculatedIntegral1s2px = boxArea * sum1s2px/Double(N)
        
        return (calculatedIntegral1s1s, error1s1s, calculatedIntegral1s2px)
    }
    
    /// calculate1s1sError
    /// Calculates the error in the overlap integral of the 1s-1s orbitals given the spacing and the numerical integral
    /// - Parameters:
    ///   - R: the interatomic spacing in units of Bohr length a0
    ///   - numericalIntegral: the calculated numerical integral to find the error for
    /// - Returns: the error in the overlap integral compared to the calculated analytic solution at R
    func calculate1s1sError(R: Double, numericalIntegral: Double) async -> Double {
        let analyticIntegral = exp(-R) * (1+R+pow(R,2)/3.0)
        let numerator = abs(numericalIntegral - analyticIntegral)
        let error = log10(numerator/analyticIntegral)
        return error
    }
    
    /// wavefunction1s
    /// Calculates the wavefunction 1s without constants
    /// - Parameters:
    ///   - r: the radius to find the value of the wavefunction at in units of Bohr length a0
    /// - Returns: the wavefunction 1s without the constants
    func wavefunction1s(r: Double) async -> Double {
        let psi = exp(-r)
        return psi
    }
    
    /// wavefunction2px
    /// Calculates the wavefunction 2px without constants
    /// - Parameters:
    ///   - r: the radius to find the value of the wavefunction at in units of Bohr length a0
    ///   - theta: the angle theta to evaluate the wavefunction at
    ///   - phi: the angle phi to evaluate the wavefunction at
    /// - Returns: the wavefunction 2px without the constants
    func wavefunction2px(r: Double, theta: Double, phi: Double) async -> Double {
        let psi = r * exp(-r/2) * sin(theta) * cos(phi)
        return psi
    }
    
    /// updateIntegral1s1sString
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter text: contains the string containing the current value of the integral
    @MainActor func updateIntegral1s1sString(text:String) {
        self.integral1s1sString = text
    }
    
    /// updateError1s1sString
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter text: contains the string containing the current value of the integral
    @MainActor func updateError1s1sString(text:String) {
        self.error1s1sString = text
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
