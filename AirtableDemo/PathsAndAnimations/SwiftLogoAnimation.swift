//
//  ButtonColor.swift
//  MyProduct
//
//  Created by Adrien on 02/11/2020.
//

import MapKit
import SwiftUI

struct SwiftLogoAnimation: View {
    @State private var angle = 0.0
    @State var resetStrokes: Bool = true
    @State var strokeStart: CGFloat = 0
    @State var strokeEnd: CGFloat = 0
    @State private var firstColor: Color = .white
    @State private var secondColor: Color = .white
    @State private var oldColors: [Color] = [.white]
    @State private var newColors: [Color] = [.white]
    @State private var colorsChanged = false
    @State private var flipped = false

    func changeColors(colors: [Color]) {
        if colorsChanged {
            oldColors = colors
        } else {
            newColors = colors
        }
        colorsChanged.toggle()
    }

    func fillGradient(colors: [Color]) -> LinearGradient {
        LinearGradient(gradient: Gradient(colors: colors), startPoint: .leading, endPoint: .trailing)
    }

    @State private var lineWidth: CGFloat = 1
    @State private var shadowRadius: CGFloat = 0

    var body: some View {
        ZStack {
            ZStack {
                ShapeView(bezier: .swiftLogo, pathBounds: UIBezierPath.swiftLogo.bounds)
                    .fill(
                        Color.black
                    )
                    .opacity(0.5)
                    .zIndex(flipped ? 1 : 0)

                ShapeView(bezier: .swiftLogo, pathBounds: UIBezierPath.swiftLogo.bounds)
                    .fill(
                        fillGradient(colors: oldColors)
                    )
                    .shadow(color: shadowRadius == 0 ? .white : .gray, radius: shadowRadius, x: -1 * shadowRadius / 2, y: shadowRadius / 2)

                ShapeView(bezier: .swiftLogo, pathBounds: UIBezierPath.swiftLogo.bounds)
                    .fill(
                        fillGradient(colors: newColors)
                    )

                    .opacity(colorsChanged ? 1 : 0)
                ShapeView(bezier: .swiftLogo, pathBounds: UIBezierPath.swiftLogo.bounds)
                    .trim(from: strokeStart, to: strokeEnd)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10))
                // .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
            }
            
            .rotation3DEffect(
                Angle(degrees: angle),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )

            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
//                                        if (self.strokeEnd >= 1) {
//                                            if (self.resetStrokes) {
//                                                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
//                                                    self.strokeEnd = 0
//                                                    self.strokeStart = 0
//                                                    self.resetStrokes.toggle()
//                                                }
//                                                self.resetStrokes = false
//                                            }
//                                        }
//                                        withAnimation(Animation.easeOut(duration: 0.5)) {
//                                            self.strokeEnd += 0.1
                    ////                                            self.strokeStart = self.strokeEnd - 0.3
//                                        }
                }
                withAnimation(Animation.linear(duration: 2)) {
                    self.strokeEnd = 1
//                                            self.strokeStart = self.strokeEnd - 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.linear(duration: 2)) {
                        changeColors(colors: [.white, .red])
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation(.linear(duration: 2)) {
                        changeColors(colors: [.orange, .red])
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    withAnimation(.linear(duration: 2)) {
                        lineWidth = 0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    withAnimation(Animation.linear(duration: 1)) {
                        angle = 90
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
                    flipped = true
                    withAnimation(Animation.linear(duration: 2)) {
                        angle = 270
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
                    flipped = false
                    withAnimation(Animation.linear(duration: 1)) {
                        angle = 360
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                    withAnimation(Animation.linear(duration: 2)) {
                        shadowRadius = 4
                    }
                }
            }
        }
    }
}

struct SwiftLogoAnimation_Previews: PreviewProvider {
    static var previews: some View {
        SwiftLogoAnimation()
    }
}

struct ShapeView: Shape {
    let bezier: UIBezierPath
    let pathBounds: CGRect
    func path(in rect: CGRect) -> Path {
        let pointScale = (rect.width > rect.height) ?
            min(pathBounds.height, pathBounds.width) :
            max(pathBounds.height, pathBounds.width)
        let pointTransform = CGAffineTransform(scaleX: 1 / pointScale, y: 1 / pointScale)
        let path = Path(bezier.cgPath).applying(pointTransform)
        let multiplier = min(rect.width, rect.height)
        let transform = CGAffineTransform(scaleX: multiplier, y: multiplier)
        return path.applying(transform)
    }
}

extension UIBezierPath {
    static func calculateBounds(paths: [UIBezierPath]) -> CGRect {
        let myPaths = UIBezierPath()
        for path in paths {
            myPaths.append(path)
        }
        return (myPaths.bounds)
    }

    static var swiftLogo: UIBezierPath {
        let shape = UIBezierPath()
        shape.move(to: CGPoint(x: 29.89, y: 33.05))
        shape.addCurve(to: CGPoint(x: 12.35, y: 33.25), controlPoint1: CGPoint(x: 25.22, y: 35.74), controlPoint2: CGPoint(x: 18.8, y: 36.02))
        shape.addCurve(to: CGPoint(x: 0, y: 22.69), controlPoint1: CGPoint(x: 7.12, y: 31.03), controlPoint2: CGPoint(x: 2.78, y: 27.14))
        shape.addCurve(to: CGPoint(x: 4.56, y: 25.47), controlPoint1: CGPoint(x: 1.33, y: 23.8), controlPoint2: CGPoint(x: 2.89, y: 24.69))
        shape.addCurve(to: CGPoint(x: 22.58, y: 25.48), controlPoint1: CGPoint(x: 11.23, y: 28.59), controlPoint2: CGPoint(x: 17.89, y: 28.38))
        shape.addCurve(to: CGPoint(x: 22.58, y: 25.47), controlPoint1: CGPoint(x: 22.58, y: 25.47), controlPoint2: CGPoint(x: 22.58, y: 25.47))
        shape.addCurve(to: CGPoint(x: 6.01, y: 8.23), controlPoint1: CGPoint(x: 15.9, y: 20.35), controlPoint2: CGPoint(x: 10.23, y: 13.68))
        shape.addCurve(to: CGPoint(x: 3.78, y: 5.23), controlPoint1: CGPoint(x: 5.12, y: 7.34), controlPoint2: CGPoint(x: 4.45, y: 6.23))
        shape.addCurve(to: CGPoint(x: 19.91, y: 17.46), controlPoint1: CGPoint(x: 8.9, y: 9.9), controlPoint2: CGPoint(x: 17.02, y: 15.79))
        shape.addCurve(to: CGPoint(x: 8.56, y: 3.23), controlPoint1: CGPoint(x: 13.79, y: 11.01), controlPoint2: CGPoint(x: 8.34, y: 3))
        shape.addCurve(to: CGPoint(x: 27.25, y: 18.57), controlPoint1: CGPoint(x: 18.24, y: 13.01), controlPoint2: CGPoint(x: 27.25, y: 18.57))
        shape.addCurve(to: CGPoint(x: 27.96, y: 19.01), controlPoint1: CGPoint(x: 27.55, y: 18.74), controlPoint2: CGPoint(x: 27.78, y: 18.88))
        shape.addCurve(to: CGPoint(x: 28.47, y: 17.46), controlPoint1: CGPoint(x: 28.16, y: 18.51), controlPoint2: CGPoint(x: 28.33, y: 18))
        shape.addCurve(to: CGPoint(x: 24.36, y: 0), controlPoint1: CGPoint(x: 30.03, y: 11.79), controlPoint2: CGPoint(x: 28.25, y: 5.34))
        shape.addCurve(to: CGPoint(x: 36.48, y: 24.25), controlPoint1: CGPoint(x: 33.36, y: 5.45), controlPoint2: CGPoint(x: 38.7, y: 15.68))
        shape.addCurve(to: CGPoint(x: 36.29, y: 24.93), controlPoint1: CGPoint(x: 36.42, y: 24.48), controlPoint2: CGPoint(x: 36.36, y: 24.7))
        shape.addCurve(to: CGPoint(x: 36.37, y: 25.02), controlPoint1: CGPoint(x: 36.32, y: 24.96), controlPoint2: CGPoint(x: 36.34, y: 24.99))
        shape.addCurve(to: CGPoint(x: 39.04, y: 35.37), controlPoint1: CGPoint(x: 40.82, y: 30.59), controlPoint2: CGPoint(x: 39.59, y: 36.48))
        shape.addCurve(to: CGPoint(x: 29.89, y: 33.05), controlPoint1: CGPoint(x: 36.62, y: 30.65), controlPoint2: CGPoint(x: 32.16, y: 32.09))
        shape.addLine(to: CGPoint(x: 29.89, y: 33.05))
        shape.close()
        return shape
    }
}
