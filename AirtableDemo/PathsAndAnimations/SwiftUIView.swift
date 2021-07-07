//
//  SwiftUIView.swift
//  AirtableDemo
//
//  Created by Admin on 21/06/2021.
//

import SwiftUI

struct SwiftUIView: View {
    @State private var progress: CGFloat = 0
    var body: some View {
        TestPath(progress: progress, x: [100, 20, 40, 20, 140, 20, 40, 320, 140], y: [20, 145, 387, 120, 40, 120, 240, 20, 240], endX: [300, 120, 70, 220, 140, 220, 40, 20, 340], endY: [120, 75, 187, 120, 340, 120, 40, 20, 140])
            .frame(width: 100)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever() ) {
                    progress = 1
                }
            }
    }
}


struct TestPath: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    var x: [CGFloat]
    var y: [CGFloat]
    
    var endX: [CGFloat]
    var endY: [CGFloat]
    
    var diffX: [CGFloat] {
        zip(endX, x).map {$0.0 - $0.1}
    }
    var diffY: [CGFloat] {
        zip(endY, y).map {$0.0 - $0.1}
    }
    
    var currentX: [CGFloat] {
        zip(x, diffX).map{ $0.0 + $0.1 * progress}
    }
    var currentY: [CGFloat] {
        zip(y, diffY).map{ $0.0 + $0.1 * progress}
    }


    func path(in rect: CGRect) -> Path {
        let newOrigin = CGPoint(x: 0, y: 0)
        var path = Path()
        path.move(to: newOrigin)
        for i in x.indices {
            path.addLine(to: CGPoint(x: currentX[i], y: currentY[i]))
        }
        
        path.addLine(to: newOrigin)
        //path.closeSubpath()
        return path
    }
    
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
            
    }
}

