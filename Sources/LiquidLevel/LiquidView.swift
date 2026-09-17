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
/// 既定の `.fill` モードではコンテンツに「傾いた容器の水平外接矩形」のサイズが与えられる。
/// そのため `alignment: .bottom` などで下寄せすると、端末を斜めにしたときに
/// 菱形の最下点にコンテンツが沈む。コンテンツ全体を欠けずに見せたい場合は `.fit`、
/// 一定量の液体が水平な液面で溜まる表現には `.waterline(_:)` を使う。
public struct LiquidView<Content: View>: View {
    private let fixedTilt: Angle?
    private let externalMotion: LiquidMotion?
    private let contentMode: LiquidContentMode
    private let animation: Animation?
    private let content: Content

    @State private var ownedMotion: LiquidMotion

    /// 端末のセンサーに追従する `LiquidView` を作る。
    ///
    /// - Parameters:
    ///   - contentMode: コンテンツを容器に収める方法。
    ///   - animation: 傾き変化に適用するアニメーション。`nil` でセンサー値に即時追従する。
    ///   - smoothing: センサー値に掛けるローパスフィルタの強さ (0...0.99)。
    ///   - content: 液体として表示するコンテンツ。
    public init(
        contentMode: LiquidContentMode = .fill,
        animation: Animation? = .liquid,
        smoothing: Double = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.fixedTilt = nil
        self.externalMotion = nil
        self.contentMode = contentMode
        self.animation = animation
        self.content = content()
        self._ownedMotion = State(initialValue: LiquidMotion(smoothing: smoothing))
    }

    /// 外部で管理する `LiquidMotion` を共有する `LiquidView` を作る。
    ///
    /// 複数の View でセンサーを共有したい場合や、傾きの値を別の UI にも表示したい場合に使う。
    /// `start()` / `stop()` は呼び出し側の責務。インターフェース向きは `LiquidView` が更新する。
    ///
    /// - Parameters:
    ///   - motion: 共有する傾きモデル。
    ///   - contentMode: コンテンツを容器に収める方法。
    ///   - animation: 傾き変化に適用するアニメーション。
    ///   - content: 液体として表示するコンテンツ。
    public init(
        motion: LiquidMotion,
        contentMode: LiquidContentMode = .fill,
        animation: Animation? = .liquid,
        @ViewBuilder content: () -> Content
    ) {
        self.fixedTilt = nil
        self.externalMotion = motion
        self.contentMode = contentMode
        self.animation = animation
        self.content = content()
        self._ownedMotion = State(initialValue: LiquidMotion())
    }

    /// 傾きを固定値で与える `LiquidView` を作る。プレビューやセンサーのない環境向け。
    ///
    /// - Parameters:
    ///   - tilt: 端末の傾き(画面を正面から見て時計回り正)。
    ///   - contentMode: コンテンツを容器に収める方法。
    ///   - animation: 傾き変化に適用するアニメーション。
    ///   - content: 液体として表示するコンテンツ。
    public init(
        tilt: Angle,
        contentMode: LiquidContentMode = .fill,
        animation: Animation? = .liquid,
        @ViewBuilder content: () -> Content
    ) {
        self.fixedTilt = tilt
        self.externalMotion = nil
        self.contentMode = contentMode
        self.animation = animation
        self.content = content()
        self._ownedMotion = State(initialValue: LiquidMotion())
    }

    private var motion: LiquidMotion {
        externalMotion ?? ownedMotion
    }

    private var tilt: Angle {
        fixedTilt ?? motion.tilt
    }

    /// センサーの開始・停止をこの View が担うかどうか。
    private var ownsMotionLifecycle: Bool {
        fixedTilt == nil && externalMotion == nil
    }

    /// アニメーションの対象となる値。傾きとモードのどちらが変わっても補間する。
    private struct AnimationKey: Equatable {
        var tilt: Angle
        var mode: LiquidContentMode
    }

    public var body: some View {
        GeometryReader { proxy in
            let tilt = tilt
            let layout = LiquidGeometry.layout(
                containerSize: proxy.size,
                tilt: tilt.radians,
                mode: contentMode
            )
            content
                .frame(width: layout.size.width, height: layout.size.height)
                .rotationEffect(-tilt)
                .position(
                    x: proxy.size.width / 2 + layout.offset.width,
                    y: proxy.size.height / 2 + layout.offset.height
                )
                .animation(animation, value: AnimationKey(tilt: tilt, mode: contentMode))
        }
        .clipped()
        .background {
            if fixedTilt == nil {
                InterfaceOrientationReader { motion.interfaceOrientation = $0 }
            }
        }
        .onAppear {
            if ownsMotionLifecycle { motion.start() }
        }
        .onDisappear {
            if ownsMotionLifecycle { motion.stop() }
        }
    }
}

// MARK: - Preview

#Preview("Tilt slider") {
    @Previewable @State var degrees: Double = 30
    @Previewable @State var fraction: Double = 0.4
    @Previewable @State var modeIndex = 0

    let mode: LiquidContentMode = switch modeIndex {
    case 1: .fit
    case 2: .waterline(fraction)
    default: .fill
    }

    VStack(spacing: 24) {
        Picker("Mode", selection: $modeIndex) {
            Text("fill").tag(0)
            Text("fit").tag(1)
            Text("waterline").tag(2)
        }
        .pickerStyle(.segmented)

        LiquidView(tilt: .degrees(degrees), contentMode: mode) {
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

        LabeledContent("Tilt \(Int(degrees))°") {
            Slider(value: $degrees, in: -180...180)
        }
        LabeledContent("Level \(Int(fraction * 100))%") {
            Slider(value: $fraction, in: 0...1)
        }
        .disabled(modeIndex != 2)
    }
    .padding()
}
