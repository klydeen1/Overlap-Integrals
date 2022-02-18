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
    var boxYLength = 10.0
    var boxZLength = 10.0
    var integral1s1s = 0.0
    var integral1s2px = 0.0
    var error1s1s = 0.0
    let a0 = 5.2917721090380e-11
    var plotDataModel: PlotDataClass? = nil
    
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
        let boxVol = myBox.calculateVolume(side1Length: boundingBoxX, side2Length: boundingBoxY, side3Lenth: boundingBoxZ)
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
            // The first wavefunction will be located at the origin and will have spherical coordinates (r1, theta1, phi1)
            // The second wavefunction will be centered at (R,0,0) and will have spherical coordinates (r2, theta2, phi2)
            let r1 = sqrt(pow(x,2) + pow(y,2) + pow(z,2))
            let theta1 = atan2(sqrt(pow(x,2) + pow(y,2)), z)
            let phi1 = atan2(y, x)
            let r2 = sqrt(pow((x-R),2) + pow(y,2) + pow(z,2))
            let theta2 = atan2(sqrt(pow((x-R),2) + pow(y,2)), z)
            let phi2 = atan2(y, (x-R))
            
            // Calculate the sums for computing the average
            await sum1s1s += wavefunction1s(r: r1) * wavefunction1s(r: r2)
            await sum1s2px += wavefunction2px(r: r1, theta: theta1, phi: phi1) * wavefunction1s(r: r2)
        }
        // Multiply the sums by approproate constants
        sum1s1s *= 1/Double.pi
        sum1s2px *= 1/(Double.pi*4.0*sqrt(2.0))
        // Calculate the integrals by multiplying the average function value by the bounding box area
        calculatedIntegral1s1s = boxVol * sum1s1s/Double(N)
        let error1s1s = await calculate1s1sError(R: R, numericalIntegral: calculatedIntegral1s1s)
        calculatedIntegral1s2px = boxVol * sum1s2px/Double(N)
        
        return (calculatedIntegral1s1s, error1s1s, calculatedIntegral1s2px)
    }
    
    /// getPlotData
    /// Sets plot parameters and runs the function to generate data for the plots
    /// - Parameters:
    ///   - selector: 0 will get the plot data for the 1s-1s overlap integral and 1 will get the plot data for the 1s-2px overlap integral
    func getPlotData(selector: Int) async {
        await plotDataModel!.zeroData()
        // Set x-axis limits
        await plotDataModel!.changingPlotParameters.xMax = 13.5
        await plotDataModel!.changingPlotParameters.xMin = -0.5
        // Set other shared attributes
        await plotDataModel!.changingPlotParameters.xLabel = "R in units of a0"
        await plotDataModel!.changingPlotParameters.yLabel = "Overlap integral"
        await plotDataModel!.changingPlotParameters.lineColor = .red()
        if selector == 0 {
            // Set y-axis limits
            await plotDataModel!.changingPlotParameters.yMax = 1.0
            await plotDataModel!.changingPlotParameters.yMin = -0.1
            
            // Set title
            await plotDataModel!.changingPlotParameters.title = "Overlap integral 1s-1s vs. R"
            
            // Get plot data
            await generatePlotData(selector: selector)
        }
        else if selector == 1 {
            await plotDataModel!.zeroData()
            // Set y-axis limits
            await plotDataModel!.changingPlotParameters.yMax = 1.0
            await plotDataModel!.changingPlotParameters.yMin = -0.1
            
            // Set title
            await plotDataModel!.changingPlotParameters.title = "Overlap integral 1s-2px vs. R"
            
            // Get plot data
            await generatePlotData(selector: selector)
        }
    }
    
    /// generatePlotData
    /// Calculates the overlap integrals over an array of R and plots the data
    /// - Parameters:
    ///   - selector: 0 will get the plot data for the 1s-1s overlap integral and 1 will get the plot data for the 1s-2px overlap integral
    func generatePlotData(selector: Int) async {
        var plotIntegral1s1s: Double
        var plotError1s1s: Double
        var plotIntegral1s2px: Double
        var plotData :[plotDataType] =  []
        
        // Iterate over a range of R
        for plotR in stride(from: 0.0, through: 13.0, by: 0.5) {
            (plotIntegral1s1s, plotError1s1s, plotIntegral1s2px) = await overlapIntegrals(boundingBoxX: boxXLength, boundingBoxY: boxYLength, boundingBoxZ: boxZLength, R: plotR, N: n)
            var plotDataPoint: plotDataType = [.X: 0.0, .Y: 0.0]
            if selector == 0 {
                plotDataPoint = [.X: plotR, .Y: plotIntegral1s1s]
            }
            else if selector == 1 {
                plotDataPoint = [.X: plotR, .Y: plotIntegral1s2px]
            }
            plotData.append(contentsOf: [plotDataPoint])
        }
        await plotDataModel!.appendData(dataPoint: plotData)
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
    @MainActor func updateIntegral1s1sString(text:String) async {
        self.integral1s1sString = text
    }
    
    /// updateError1s1sString
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter text: contains the string containing the current value of the integral
    @MainActor func updateError1s1sString(text:String) async {
        self.error1s1sString = text
    }
    
    /// updateIntegral1s2pxString
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter text: contains the string containing the current value of the integral
    @MainActor func updateIntegral1s2pxString(text:String) async {
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
