import LiquidLevel
import SwiftUI

/// 実機で `LiquidView` の回転方向・各モードの挙動を確認するためのデモ画面。
struct ContentView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case fill, fit, waterline
        var id: Self { self }
    }

    @State private var motion = LiquidMotion()
    @State private var mode: Mode = .fill
    @State private var fraction = 0.4
    @State private var isManual = false
    @State private var manualDegrees = 30.0

    private var contentMode: LiquidContentMode {
        switch mode {
        case .fill: .fill
        case .fit: .fit
        case .waterline: .waterline(fraction)
        }
    }

    var body: some View {
        ZStack {
            liquid
                .ignoresSafeArea()
            VStack {
                readout
                Spacer()
                controls
            }
            .padding()
        }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }

    // MARK: - Liquid

    @ViewBuilder
    private var liquid: some View {
        if isManual {
            LiquidView(tilt: .degrees(manualDegrees), contentMode: contentMode) {
                liquidContent
            }
        } else {
            LiquidView(motion: motion, contentMode: contentMode) {
                liquidContent
            }
        }
    }

    /// 上下・左右が分かるように、上辺に液面のライン、下辺にラベルを置く
    private var liquidContent: some View {
        ZStack {
            LinearGradient(
                colors: [.cyan.opacity(0.35), .blue, .indigo],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack {
                Rectangle()
                    .fill(.white.opacity(0.8))
                    .frame(height: 3)
                Text("↑ 液面(常に水平)")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text("底 ↓")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - HUD

    private var readout: some View {
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent("tilt", value: tiltText)
            LabeledContent("orientation", value: String(describing: motion.interfaceOrientation))
            LabeledContent("sensor", value: motion.isActive ? "active" : "unavailable")
        }
        .font(.callout.monospaced())
        .padding(12)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tiltText: String {
        let degrees = isManual ? manualDegrees : motion.tilt.degrees
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 540)
            .truncatingRemainder(dividingBy: 360) - 180
        return String(format: "%+.1f° (raw %+.1f°)", normalized, degrees)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if mode == .waterline {
                LabeledContent("level \(Int(fraction * 100))%") {
                    Slider(value: $fraction, in: 0...1)
                }
            }

            Toggle("manual tilt", isOn: $isManual)
            if isManual {
                LabeledContent("\(Int(manualDegrees))°") {
                    Slider(value: $manualDegrees, in: -180...180)
                }
            }
        }
        .font(.callout.monospaced())
        .padding(12)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
