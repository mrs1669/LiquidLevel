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

    /// 容器と同じアスペクト比を保ったまま、`tilt` だけ回転させた容器に内接する最大の水平矩形のサイズ。
    ///
    /// 水平矩形 `a × (a·h/w)` の四隅が回転後の容器に収まる条件
    /// `a(|cos| + r|sin|) ≤ w`, `a(|sin| + r|cos|) ≤ h` (r = h/w) から `a` の上限を求める。
    public static func fittedSize(containerSize: CGSize, tilt: Double) -> CGSize {
        let w = containerSize.width
        let h = containerSize.height
        guard w > 0, h > 0 else { return .zero }
        let s = abs(sin(tilt))
        let c = abs(cos(tilt))
        let r = h / w
        let a = min(w / (c + r * s), h / (s + r * c))
        return CGSize(width: a, height: a * r)
    }

    /// `tilt` だけ回転させた容器に、面積比 `fraction` (0...1) の液体を入れたときの、
    /// 最下点から液面までの高さ。
    ///
    /// 最下点からの高さ `y` 以下の面積 `A(y)` は、辺の傾きから次の区分関数になる
    /// (s = |sin tilt|, c = |cos tilt|, m = min(w·s, h·c))。
    /// - 下部三角: `A = y² / (2sc)` (0 ≤ y ≤ m)
    /// - 中央平行四辺形: 幅が `m / (sc)` で一定 (m ≤ y ≤ H − m)
    /// - 上部三角: 下部と対称 (H − m ≤ y ≤ H)
    /// これを `A(y) = fraction · w · h` について解く。
    public static func waterlineHeight(containerSize: CGSize, tilt: Double, fraction: Double) -> CGFloat {
        let w = containerSize.width
        let h = containerSize.height
        guard w > 0, h > 0 else { return 0 }
        let f = min(max(fraction, 0), 1)
        let s = abs(sin(tilt))
        let c = abs(cos(tilt))
        let totalHeight = w * s + h * c
        let m = min(w * s, h * c)
        // 90° の倍数付近では容器が水平な矩形なので、水位は高さに比例する
        guard m > 1e-9 else { return f * totalHeight }

        let sc = s * c
        let totalArea = w * h
        let target = f * totalArea
        let triangleArea = m * m / (2 * sc)

        if target <= triangleArea {
            return sqrt(2 * sc * target)
        }
        if target <= totalArea - triangleArea {
            return m + (target - triangleArea) * sc / m
        }
        return totalHeight - sqrt(2 * sc * (totalArea - target))
    }

    /// `mode` に応じたコンテンツのサイズと配置を求める。
    public static func layout(containerSize: CGSize, tilt: Double, mode: LiquidContentMode) -> LiquidLayout {
        switch mode {
        case .fill:
            return LiquidLayout(size: levelBoundingBox(containerSize: containerSize, tilt: tilt))
        case .fit:
            return LiquidLayout(size: fittedSize(containerSize: containerSize, tilt: tilt))
        case .waterline(let fraction):
            let box = levelBoundingBox(containerSize: containerSize, tilt: tilt)
            let height = waterlineHeight(containerSize: containerSize, tilt: tilt, fraction: fraction)
            // 容器中心から最下点方向(画面座標での重力方向)へ、外接矩形の下半分と液体の高さの半分の差だけずらす
            let distance = (box.height - height) / 2
            return LiquidLayout(
                size: CGSize(width: box.width, height: height),
                offset: CGSize(width: distance * sin(tilt), height: distance * cos(tilt))
            )
        }
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
