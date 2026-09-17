import CoreGraphics
import Foundation

/// `LiquidView` がコンテンツを容器にどう収めるか。
public enum LiquidContentMode: Sendable, Hashable {
    /// 傾いた容器の水平外接矩形までコンテンツを広げ、容器全体を満たす(既定)。
    ///
    /// コンテンツの下辺が菱形の最下点に一致する。容器の外にはみ出た部分はクリップされる。
    case fill

    /// 容器と同じアスペクト比を保ったまま、傾いた容器に内接する最大の水平矩形に収める。
    ///
    /// コンテンツ全体が常に見える。
    case fit
}

/// `LiquidGeometry.layout(containerSize:tilt:mode:)` の結果。
public struct LiquidLayout: Equatable, Sendable {
    /// コンテンツに与える(回転前の)サイズ。
    public var size: CGSize

    /// 容器中心からのコンテンツ中心のオフセット(画面座標系)。
    public var offset: CGSize

    public init(size: CGSize, offset: CGSize = .zero) {
        self.size = size
        self.offset = offset
    }
}
