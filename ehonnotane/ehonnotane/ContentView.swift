//
//  ContentView.swift
//  ehonnotane
//
//  Created by ayu on 2025/11/15.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .onAppear {
            FontRegistration.registerFonts()
        }
}
