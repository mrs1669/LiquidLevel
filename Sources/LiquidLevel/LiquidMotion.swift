import CoreMotion
import Observation
import SwiftUI

/// CoreMotion から端末の傾きを取得して公開するモデル。
///
/// `tilt` は ±180° をまたいでも連続するようアンラップ済みなので、
/// そのまま `rotationEffect` とアニメーションに渡せる。
@MainActor
@Observable
public final class LiquidMotion {
    /// 端末の傾き(画面を正面から見て時計回り正)。アンラップ済みの連続値。
    public private(set) var tilt: Angle = .zero

    /// 現在のインターフェース向き。`LiquidView` が自動で更新する。
    public var interfaceOrientation: LiquidInterfaceOrientation = .portrait

    /// センサー更新が動作中かどうか。
    public private(set) var isActive = false

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private let updateInterval: TimeInterval
    @ObservationIgnored private let smoothing: Double

    /// - Parameters:
    ///   - updateInterval: センサー更新間隔(秒)。
    ///   - smoothing: ローパスフィルタの強さ (0 = なし, 1 に近いほど鈍る)。
    ///     `LiquidView` 側のスプリングアニメーションで十分な場合は 0 のままでよい。
    public init(updateInterval: TimeInterval = 1.0 / 60.0, smoothing: Double = 0) {
        self.updateInterval = updateInterval
        self.smoothing = min(max(smoothing, 0), 0.99)
    }

    /// センサー更新を開始する。シミュレータなど deviceMotion が使えない環境では何もしない。
    public func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = updateInterval
        isActive = true
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            let gravity = motion.gravity
            // queue に .main を指定しているので MainActor 上で実行される
            MainActor.assumeIsolated {
                self?.update(gravityX: gravity.x, gravityY: gravity.y)
            }
        }
    }

    /// センサー更新を停止する。
    public func stop() {
        manager.stopDeviceMotionUpdates()
        isActive = false
    }

    /// 重力ベクトル(デバイス座標系)から傾きを更新する。
    ///
    /// テストやセンサー以外の入力源(プレビューの Slider など)から手動で呼ぶこともできる。
    public func update(gravityX: Double, gravityY: Double) {
        let g = LiquidGeometry.gravityInInterface(
            x: gravityX,
            y: gravityY,
            orientation: interfaceOrientation
        )
        guard let raw = LiquidGeometry.tilt(gravityX: g.x, gravityY: g.y) else { return }

        let previous = tilt.radians
        let continuous = LiquidGeometry.unwrapped(raw, previous: previous)
        let filtered = previous + (continuous - previous) * (1 - smoothing)
        tilt = .radians(filtered)
    }
}
