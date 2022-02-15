//
//  IntegralCalculator.swift
//  Overlap-Integrals
//
//  Created by Katelyn Lydeen on 2/14/22.
//

import Foundation
import SwiftUI

typealias integrationFunctionHandler = (_ input: Double) -> Double

class IntegralCalculator: NSObject, ObservableObject {
    @Published var nString = ""
    @Published var rString = ""
    
    @Published var integral1s1sString = ""
    @Published var integral1s2pxString = ""
    @Published var error1s1sString = ""
    @Published var enableButton = true
    
    var n = 1
    var R = 1.0
    var integral1s1s = 0.0
    var integral1s2px = 0.0
    let a0 = 5.2917721090380e-11
    
    func calculateOverlapIntegrals() async {
        // Change upper and lower limits
        (integral1s1s, integral1s2px) = await calculateOverlapIntegrals(lowerLimit: 0.0, upperLimit: R, N: n)
        //integral1s1s = i1
        await updateIntegral1s1sString(text: "\(integral1s1s)")
        await updateIntegral1s2pxString(text: "\(integral1s2px)")
    }
    
    // General reuseable function
    func calculateIntegralMVT(lowerLimit: Double, upperLimit: Double, N: Int, functionToBeIntegrated: integrationFunctionHandler) async -> Double {
        var integral = 0.0
        var sum = 0.0
        
        for _ in stride(from: 1, through: N, by: 1) {
            let xi = Double.random(in: lowerLimit...upperLimit)
            sum += functionToBeIntegrated(xi)
        }
        integral = (upperLimit - lowerLimit)*sum/Double(N)
        return integral
    }
    
    // Example function
    func eToTheMinusX(_ input: Double) -> Double {
        return exp(-input)
    }
    
    func calculateOverlapIntegrals(lowerLimit: Double, upperLimit: Double, N: Int) async -> (Double, Double) {
        var sum1s1s = 0.0
        var sum1s2px = 0.0
        var calculatedIntegral1s1s = 0.0
        var calculatedIntegral1s2px = 0.0
        
        // Sum over 1 through N
        for _ in stride(from: 1, through: N, by: 1) {
            // Calculate random x values separately so the errors are independent
            let ri1s1s = Double.random(in: lowerLimit...upperLimit)
            let ri1s2px = Double.random(in: lowerLimit...upperLimit)
            
            // Calculate the sums for computing the average
            sum1s1s += exp(-R-2.0*ri1s1s) * pow(ri1s1s,2)
            sum1s2px += sin(ri1s2px)
        }
        calculatedIntegral1s1s = 4.0/a0 * (upperLimit - lowerLimit) * sum1s1s/Double(N)
        // calculatedIntegral1s1s = (upperLimit - lowerLimit) * sum1s1s/Double(N)
        calculatedIntegral1s2px = (upperLimit - lowerLimit) * sum1s2px/Double(N)
        
        return (calculatedIntegral1s1s, calculatedIntegral1s2px)
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
