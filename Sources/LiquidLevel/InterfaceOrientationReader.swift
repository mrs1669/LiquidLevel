import SwiftUI
import UIKit

/// 自身が所属する `UIWindowScene` のインターフェース向きを監視して通知する不可視 View。
struct InterfaceOrientationReader: UIViewRepresentable {
    var onChange: @MainActor (LiquidInterfaceOrientation) -> Void

    func makeUIView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.onChange = onChange
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: ReaderView, context: Context) {
        uiView.onChange = onChange
    }

    final class ReaderView: UIView {
        var onChange: (@MainActor (LiquidInterfaceOrientation) -> Void)?
        private var last: LiquidInterfaceOrientation?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            report()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            report()
        }

        private func report() {
            guard
                let raw = window?.windowScene?.interfaceOrientation,
                let orientation = LiquidInterfaceOrientation(raw),
                orientation != last
            else { return }
            last = orientation
            // レイアウト中に SwiftUI の状態を書き換えないよう次のランループで通知する
            let onChange = onChange
            Task { @MainActor in
                onChange?(orientation)
            }
        }
    }
}

extension LiquidInterfaceOrientation {
    init?(_ orientation: UIInterfaceOrientation) {
        switch orientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        case .unknown: return nil
        @unknown default: return nil
        }
    }
}
