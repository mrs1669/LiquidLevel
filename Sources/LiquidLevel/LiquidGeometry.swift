import Foundation

/// 傾きと容器サイズから「液体」のレイアウトを求める純粋関数群。
///
/// 角度はすべてラジアン。傾き `tilt` は「画面を正面から見て端末が時計回りに回転した角度」で、
/// コンテンツを水平に保つには `-tilt` だけ回転させる。
public enum LiquidGeometry {
    /// 重力の水平成分がこれ未満(単位: G)のときは端末がほぼ水平とみなし、傾きを更新しない。
    public static let flatThreshold: Double = 0.2

    /// 重力ベクトル(画面座標系: x が右, y が上)から端末の傾きを求める。
    ///
    /// - Returns: 時計回り正の傾き(ラジアン)。端末がほぼ水平で傾きが定義できない場合は `nil`。
    public static func tilt(gravityX: Double, gravityY: Double) -> Double? {
        guard hypot(gravityX, gravityY) >= flatThreshold else { return nil }
        // 直立時 gravity = (0, -1) で 0、時計回りに回すと x が正になる
        return atan2(gravityX, -gravityY)
    }

    /// `angle` を `previous` に連続するよう 2π の倍数だけずらす。
    ///
    /// ±π をまたいだときに逆回転のアニメーションが走らないようにするためのアンラップ処理。
    public static func unwrapped(_ angle: Double, previous: Double) -> Double {
        var delta = (angle - previous).truncatingRemainder(dividingBy: 2 * .pi)
        if delta > .pi {
            delta -= 2 * .pi
        } else if delta < -.pi {
            delta += 2 * .pi
        }
        return previous + delta
    }

    /// 容器を `tilt` だけ回転させたときの、水平方向に沿った外接矩形のサイズ。
    ///
    /// コンテンツをこのサイズにして `-tilt` 回転させ容器中心に置くと、
    /// コンテンツの下辺が回転した容器(菱形)の最下点に一致する。
    public static func levelBoundingBox(containerSize: CGSize, tilt: Double) -> CGSize {
        let s = abs(sin(tilt))
        let c = abs(cos(tilt))
        return CGSize(
            width: containerSize.width * c + containerSize.height * s,
            height: containerSize.width * s + containerSize.height * c
        )
    }

    /// デバイス座標系の重力ベクトルを、現在のインターフェース向きの画面座標系に変換する。
    public static func gravityInInterface(
        x: Double,
        y: Double,
        orientation: LiquidInterfaceOrientation
    ) -> (x: Double, y: Double) {
        switch orientation {
        case .portrait: (x, y)
        case .portraitUpsideDown: (-x, -y)
        case .landscapeLeft: (y, -x)
        case .landscapeRight: (-y, x)
        }
    }
}
