import Foundation

/// 画面(インターフェース)の向き。
///
/// `UIInterfaceOrientation` に依存せず幾何計算をテストできるようにするための独自定義。
public enum LiquidInterfaceOrientation: Sendable, Hashable {
    case portrait
    case portraitUpsideDown
    /// 端末を時計回りに 90° 回した状態(ホームボタン/インジケータが左)
    case landscapeLeft
    /// 端末を反時計回りに 90° 回した状態(ホームボタン/インジケータが右)
    case landscapeRight
}
