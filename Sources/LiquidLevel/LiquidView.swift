import SwiftUI

public extension Animation {
    /// 液体が揺れて落ち着くような、少しオーバーシュートするスプリング。`LiquidView` のデフォルト。
    static var liquid: Animation {
        .spring(response: 0.35, dampingFraction: 0.65)
    }
}

/// 端末の傾きに追従してコンテンツを常に水平に保ち、容器の最下点まで液体のように満たす View。
///
/// ```swift
/// LiquidView {
///     Text("hoge")
///         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
/// }
/// ```
///
/// コンテンツには「傾いた容器の水平外接矩形」のサイズが与えられる。
/// そのため `alignment: .bottom` などで下寄せすると、端末を斜めにしたときに
/// 菱形の最下点にコンテンツが沈む。
public struct LiquidView<Content: View>: View {
    private let fixedTilt: Angle?
    private let animation: Animation?
    private let content: Content

    @State private var motion: LiquidMotion

    /// 端末のセンサーに追従する `LiquidView` を作る。
    ///
    /// - Parameters:
    ///   - animation: 傾き変化に適用するアニメーション。`nil` でセンサー値に即時追従する。
    ///   - smoothing: センサー値に掛けるローパスフィルタの強さ (0...0.99)。
    ///   - content: 液体として表示するコンテンツ。
    public init(
        animation: Animation? = .liquid,
        smoothing: Double = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.fixedTilt = nil
        self.animation = animation
        self.content = content()
        self._motion = State(initialValue: LiquidMotion(smoothing: smoothing))
    }

    /// 傾きを固定値で与える `LiquidView` を作る。プレビューやセンサーのない環境向け。
    ///
    /// - Parameters:
    ///   - tilt: 端末の傾き(画面を正面から見て時計回り正)。
    ///   - animation: 傾き変化に適用するアニメーション。
    ///   - content: 液体として表示するコンテンツ。
    public init(
        tilt: Angle,
        animation: Animation? = .liquid,
        @ViewBuilder content: () -> Content
    ) {
        self.fixedTilt = tilt
        self.animation = animation
        self.content = content()
        self._motion = State(initialValue: LiquidMotion())
    }

    private var tilt: Angle {
        fixedTilt ?? motion.tilt
    }

    public var body: some View {
        GeometryReader { proxy in
            let tilt = tilt
            let box = LiquidGeometry.levelBoundingBox(containerSize: proxy.size, tilt: tilt.radians)
            content
                .frame(width: box.width, height: box.height)
                .rotationEffect(-tilt)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .animation(animation, value: tilt)
        }
        .clipped()
        .background {
            if fixedTilt == nil {
                InterfaceOrientationReader { motion.interfaceOrientation = $0 }
            }
        }
        .onAppear {
            if fixedTilt == nil { motion.start() }
        }
        .onDisappear {
            motion.stop()
        }
    }
}

// MARK: - Preview

#Preview("Tilt slider") {
    @Previewable @State var degrees: Double = 30

    VStack(spacing: 24) {
        LiquidView(tilt: .degrees(degrees)) {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [.cyan.opacity(0.3), .blue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Text("hoge")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.bottom, 16)
            }
        }
        .frame(width: 240, height: 320)
        .border(.secondary)

        Slider(value: $degrees, in: -180...180)
        Text("\(Int(degrees))°")
            .monospacedDigit()
    }
    .padding()
}
