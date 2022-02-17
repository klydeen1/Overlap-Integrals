//
//  ContentView.swift
//  Shared
//
//  Created by Katelyn Lydeen on 2/14/22.
//

import SwiftUI
import CorePlot

typealias plotDataType = [CPTScatterPlotField : Double]

struct ContentView: View {
    // Setup the GUI to monitor the data
    @ObservedObject var integrator = IntegralCalculator()
    @ObservedObject var plotDataModel = PlotDataClass(fromLine: true)
    // @EnvironmentObject var plotData: PlotClass
    
    @State var nString = "10000"
    @State var rString = "1.0"
    @State var boxXString = "10.0"
    @State var boxYString = "5.0"
    @State var boxZString = "5.0"
    @State var integral1s1sString = ""
    @State var integral1s2pxString = ""
    @State var error1s1sString = ""
    @State var selector = 0
                                                      
    var body: some View {
        HStack{
            VStack{
                VStack(alignment: .center) {
                    Text("Number of Terms N")
                        .font(.callout)
                        .bold()
                    TextField("# Number of Terms N", text: $nString)
                        .padding()
                }
                .padding(.top, 5.0)
                
                HStack {
                    VStack(alignment: .center) {
                        Text("Box Length (x)")
                            .font(.callout)
                            .bold()
                        TextField("# Box Length (x)", text: $boxXString)
                            .padding()
                    }
                    
                    VStack(alignment: .center) {
                        Text("Box Length (y)")
                            .font(.callout)
                            .bold()
                        TextField("# Box Length (y)", text: $boxYString)
                            .padding()
                    }
                    
                    VStack(alignment: .center) {
                        Text("Box Length (z)")
                            .font(.callout)
                            .bold()
                        TextField("# Box Length (z)", text: $boxZString)
                            .padding()
                    }
                }
                
                VStack(alignment: .center) {
                    Text("Interatomic spacing R in units a0")
                        .font(.callout)
                        .bold()
                    TextField("# Interatomic spacing R in units a0", text: $rString)
                        .padding()
                }
                
                HStack {
                    VStack(alignment: .center) {
                        Text("Overlap Integral: 1s and 1s")
                            .font(.callout)
                            .bold()
                        TextField("# Overlap Integral: 1s and 1s", text: $integral1s1sString)
                            .padding()
                    }
                    
                    VStack(alignment: .center) {
                        Text("Log of Error in Overlap Integral: 1s and 1s")
                            .font(.callout)
                            .bold()
                        TextField("# Log of Error in Overlap Integral: 1s and 1s", text: $error1s1sString)
                            .padding()
                    }
                }
                
                VStack(alignment: .center) {
                    Text("Overlap Integral: 1s and 2px")
                        .font(.callout)
                        .bold()
                    TextField("# Overlap Integral: 1s and 2px", text: $integral1s2pxString)
                        .padding()
                }
                
                HStack {
                    Button("Cycle Calculation", action: {Task.init{await self.calculateIntegrals()}})
                        .padding()
                        .disabled(integrator.enableButton == false)
                    
                    Button("Clear", action: {self.clear()})
                        .padding()
                        .disabled(integrator.enableButton == false)
                }
                
                HStack {
                    Button("Plot 1s-1s Overlap", action: {Task.init{
                        self.selector = 0
                        await self.generatePlots()
                        }})
                        .padding()
                        .disabled(integrator.enableButton == false)
                           
                    Button("Plot 1s-2px Overlap", action: {Task.init {
                        self.selector = 1
                        await self.generatePlots()
                        }})
                        .padding()
                        .disabled(integrator.enableButton == false)
                }
                
                if (!integrator.enableButton){
                    ProgressView()
                }
            }
            // Stop the window shrinking to zero.
            Spacer()
            CorePlot(dataForPlot: $plotDataModel.plotData, changingPlotParameters: $plotDataModel.changingPlotParameters)
                .setPlotPadding(left: 10)
                .setPlotPadding(right: 10)
                .setPlotPadding(top: 10)
                .setPlotPadding(bottom: 10)
                .padding()
            Divider()
        }
    }
    
    /// calculateIntegrals
    /// Calculate the 1s-1s and 1s-2px overlap integrals at the user selected parameters
    func calculateIntegrals() async {
        integrator.setButtonEnable(state: false)
        
        integrator.n = Int(nString)!
        integrator.R = Double(rString)!
        integrator.boxXLength = Double(boxXString)!
        integrator.boxYLength = Double(boxYString)!
        integrator.boxZLength = Double(boxZString)!
        
        await integrator.calculateOverlapIntegrals()
        
        integral1s1sString = integrator.integral1s1sString
        error1s1sString = integrator.error1s1sString
        integral1s2pxString = integrator.integral1s2pxString
        
        integrator.setButtonEnable(state: true)
    }
    
    @MainActor func setupPlotDataModel() {
        integrator.plotDataModel = self.plotDataModel
    }
    
    /// generatePlots
    /// Plots either the 1s-1s or 1s-2px overlap integral vs. R
    /// The size of the bounding box and the number of iterations for the integrals are taken from user input
    func generatePlots() async {
        setupPlotDataModel()
        
        integrator.setButtonEnable(state: false)
        
        integrator.n = Int(nString)!
        integrator.boxXLength = Double(boxXString)!
        integrator.boxYLength = Double(boxYString)!
        integrator.boxZLength = Double(boxZString)!
        
        await integrator.getPlotData(selector: self.selector)
        
        integrator.setButtonEnable(state: true)
    }
    
    func clear() {
        plotDataModel.zeroData()
        nString = "10000"
        rString = "1.0"
        boxXString = "10.0"
        boxYString = "5.0"
        boxZString = "5.0"
        integral1s1sString =  ""
        integral1s2pxString = ""
        error1s1sString = ""
        integrator.error1s1s = 0.0
        integrator.integral1s1s = 0.0
        integrator.integral1s2px = 0.0
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
