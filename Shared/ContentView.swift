//
//  ContentView.swift
//  Shared
//
//  Created by Katelyn Lydeen on 2/14/22.
//

import SwiftUI

struct ContentView: View {
    @State var nString = "10000"
    @State var rString = "1.0"
    @State var boxXString = "10.0"
    @State var boxYString = "5.0"
    @State var boxZString = "5.0"
    @State var integral1s1sString = ""
    @State var integral1s2pxString = ""
    @State var error1s1sString = ""
    
    // Setup the GUI to monitor the data from the Monte Carlo Integral Calculator
    @ObservedObject var integrator = IntegralCalculator()
                                                      
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
                
                Button("Cycle Calculation", action: {Task.init{await self.calculateIntegrals()}})
                    .padding()
                    .disabled(integrator.enableButton == false)
                
                Button("Clear", action: {self.clear()})
                    .padding(.bottom, 5.0)
                    .disabled(integrator.enableButton == false)
                
                if (!integrator.enableButton){
                    ProgressView()
                }
            }
            .padding()
        }
    }
    
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
    
    func clear() {
        nString = "10000"
        rString = "1.0"
        boxXString = "5.0"
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
