//
//  GrapheView.swift
//  PromoAvril
//
//  Created by Admin on 27/04/2021.
//

import SwiftUI



struct GrapheViewTest: View {
    var colors: [Color] = [.red, .green, .orange, .purple, .yellow]
    @State var currenColor: Color = .blue

    var body: some View {
        VStack {
            GrapheView(color: currenColor)
                .frame(width: 220, height: 100, alignment: .center)
                .cornerRadius(10)

            Button(action: {
                var newColor = currenColor
                while currenColor == newColor {
                    newColor = colors.randomElement()!
                }
                currenColor = newColor
            }) {
                Text("Tracer le graph")
            }
            .padding(.top, 20)
        }
    }
}

struct GrapheView: View {
    @State private var prevColor: Color // only stores initial color, never changes
    var color: Color // only used to update layer (with onChange)
    @State private var layer: (color: Color, progress: CGFloat)? = nil // new color and progress

    // helpers : unwrap optionals
    var layerColor: Color {
        layer?.color ?? .clear
    }
    var layerProgress: CGFloat {
        layer?.progress ?? 0
    }
    
    init(color: Color) {
        _prevColor = State(initialValue: color)
        // en déclarant la prevColor en State sa valeur ne sera pas changée par la vue parente
        self.color = color
        // à l'inverse la color sera updatée si elle change "au dessus"
    }

    var body: some View {
        
                ZStack {
                    Rectangle()
                        .foregroundColor(self.prevColor)
                    Graphe(progress: layerProgress)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [layerColor, Color.blue]), startPoint: .top, endPoint: .bottom)
                        )
                    Graphe(closed: false, progress: layerProgress)
                        .stroke(Color.black.opacity(0.5), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }

            .onChange(of: self.color) { color in
                // ceci est un tuple
                layer = (color: color, progress: 0)

                withAnimation(.linear(duration: 1.3)) {
                    // la variable que l'animation va progressivement faire bouger de 0 à 1 c'est celle-ci
                    layer?.progress = 1.0
                }
            }
    }
}

struct Graphe: Shape {
    // values
    var values: [Double] = [121.39, 119.90, 122.15, 123.00, 125.90, 126.21, 127.90, 130.36, 133.00, 131.24, 134.43, 132.03, 134.50, 134.16, 134.84, 133.11, 133.50, 131.94, 134.32, 124.48]
    var closed = true
    // margin
    var marginX: Double = 10.00
    var marginY: Double = 10.00

    // size
    var width: Double = 220
    var height: Double = 110

    var scaleX: Double {
        return (width - marginX) / Double(values.count)
    }

    var scaleY: Double {
        guard let maxY = values.max() else { return 1 }
        return (height - 2.00 * marginY) / (maxY - minY)
    }

    var minY: Double {
        return values.min() ?? 0.0
    }

    var maxY: Double {
        return values.max() ?? 0.0
    }

    // for animation
    var progress: CGFloat
    var animatableData: CGFloat {
        get { return progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        return leftToRight(rect: rect)
    }

    func getPosition(index: Int) -> CGPoint {
        guard !values.isEmpty else { return .zero }
        if index <= 0 {
            return CGPoint(x: CGFloat(marginX), y: CGFloat((height - (values[0] - minY) * scaleY) - marginY))
        }
        return CGPoint(x: CGFloat(marginX + Double(index) * scaleX), y: CGFloat((height - (values[index] - minY) * scaleY) - marginY))
    }

    // for the last point
    // (sa position dépend de la progression de l'animation)
    func getPositionOfTheLastOne(nbOfCompleted: Int, percentOfTheLast: CGFloat) -> CGPoint {
        let indice = nbOfCompleted
        return CGPoint(x: getPosition(index: indice - 1).x + (getPosition(index: indice).x - getPosition(index: indice - 1).x) * percentOfTheLast, y: getPosition(index: indice - 1).y + (getPosition(index: indice).y - getPosition(index: indice - 1).y) * percentOfTheLast)
    }

    func leftToRight(rect: CGRect) -> Path {
        guard progress != 0 else { return Path() }
        let newProgress = progress * CGFloat(values.count)
        var nbOfCompleted: Int = Int(newProgress)
        if nbOfCompleted == values.count {
            nbOfCompleted -= 1
        }
        let percentOfTheLast = newProgress - CGFloat(nbOfCompleted)

        var path = Path()
        path.move(to: getPosition(index: 0))

        // tracer les segments complets
        values.indices.filter({ $0 < nbOfCompleted }).forEach { indice in
            path.addLine(to: getPosition(index: indice))
        }

        // tracer le dernier segment (incomplet)
        path.addLine(to: getPositionOfTheLastOne(nbOfCompleted: nbOfCompleted, percentOfTheLast: percentOfTheLast))

        // fermer la forme
        if closed {
            path.addLine(to: CGPoint(x: getPositionOfTheLastOne(nbOfCompleted: nbOfCompleted, percentOfTheLast: percentOfTheLast).x, y: CGFloat(maxY)))

            path.addLine(to: CGPoint(x: CGFloat(marginX), y: CGFloat(110.00 - marginY)))

            path.closeSubpath()
        }
        return path
    }
}



struct GrapheView_Previews: PreviewProvider {
    static var previews: some View {
        GrapheViewTest()
            .preferredColorScheme(.dark)
    }
}
