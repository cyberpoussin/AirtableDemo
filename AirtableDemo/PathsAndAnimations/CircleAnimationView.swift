//
//  CircleAnimationView.swift
//  PromoAvril
//
//  Created by Admin on 28/04/2021.
//

import SwiftUI

struct BoundingCircle: View {
    @State private var rebound = false
    @State private var offset: CGSize = .zero
    var body: some View {
        CircleAnimationView(rebound: rebound)
            .scaleEffect(0.8)
            .offset(offset)
            .onTapGesture {
                withAnimation(.linear(duration: 1)) {
                    offset.height = 100
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    rebound.toggle()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                    withAnimation(.linear(duration: 1)) {
                        offset.height = 0
                    }
                }
            }
    }
}

struct CircleAnimationView: View {
    @State private var progress: CGFloat = 0
    var rebound = false
    
    var body: some View {
        CustomCircle(progress: progress)
            .onChange(of: rebound, perform: { value in
                    withAnimation(.linear(duration: 1)) {
                        progress = 0.175
                        
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation(.linear(duration: 1)) {
                            progress = 0
                        }
                    }
            })
    }
}

struct Circle2AnimationView: View {
    @State private var progress: CGFloat = 0.2
    var rebound = false
    
    var body: some View {
        VStack {
            CustomCircle(progress: progress)
            Text(progress.description)
            Slider(value: $progress, in: 0...1)
        }
    }
}


struct CustomCircle: Shape {
    var progress: CGFloat = 0
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        circle(rect: rect)
    }
    func circle(rect: CGRect) -> Path {
        let a: CGFloat = rect.height / 2.0
        let b: CGFloat = rect.width / 2.0

        let c = pow(pow(a, 2) + pow(b, 2), 0.5) // a^2 + b^2 = c^2  --> Solved for 'c'
        // c = radius of final circle

        let radius = c * (1/2)

        // Build Circle Path
        var path = Path()
//        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY + progress * 2), radius: radius, startAngle: Angle(degrees: 300), endAngle: Angle(degrees: 240), clockwise: true)
        
        //path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: radius , startAngle: modifiedStart, endAngle: modifiedEnd, clockwise: true)
        let newOrigin = CGPoint(x: rect.origin.x, y: rect.height/2 + (rect.width/2))
        //path.move(to: CGPoint(x: 0,y: 0))
//        path.addEllipse(in: CGRect(origin: newOrigin, size: CGSize(width: rect.width * (1 + progress), height: -rect.width * (1 - progress))))
        
        let newHeight = rect.size.height * (1 - progress)
        let diffHeight = rect.size.height - newHeight
        let newY = rect.origin.y + diffHeight
        
        let newWidth = rect.size.width * (1 + progress)
        let diffWidth = rect.size.width - newWidth
        let newX = rect.origin.x + diffWidth/2
        path.addEllipse(in: CGRect(origin: CGPoint(x: newX, y: newY), size: CGSize(width: newWidth, height: newHeight)))
        return path

    }
    
}


struct CircleAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Circle2AnimationView()
            BoundingCircle()
        }
    }
}
