# LiquidLevel

端末の傾きに追従してコンテンツを常に水平に保ち、容器の最下点まで **液体のように満たす** SwiftUI View です。

端末を斜めにすると、容器(View の枠)は重力に対して菱形に見えます。
`LiquidView` はコンテンツを単に逆回転させるだけでなく、菱形の最下点まで届くサイズに広げるため、
まるで容器に注がれた液体のようにコンテンツが沈みます。

## 動作環境

- iOS 17.0+
- Swift 6.0+ / Xcode 16+

## インストール

Swift Package Manager で追加します。

```swift
dependencies: [
    .package(url: "https://github.com/mrs1669/LiquidLevel.git", from: "0.1.0"),
]
```

## 使い方

```swift
import LiquidLevel

struct ContentView: View {
    var body: some View {
        LiquidView {
            Text("hoge")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: 240, height: 320)
    }
}
```

コンテンツには「傾いた容器の水平外接矩形」のサイズが与えられます。
`alignment: .bottom` などで下寄せすると、端末を傾けたときに菱形の最下点へコンテンツが沈みます。

### コンテンツモード

```swift
// 既定。傾いた容器の水平外接矩形まで広げ、容器全体を満たす
LiquidView(contentMode: .fill) { ... }

// 容器と同じアスペクト比を保ったまま容器に内接させる。コンテンツ全体が常に見える
LiquidView(contentMode: .fit) { ... }
```

### アニメーションの調整

```swift
// デフォルトは少し揺れて落ち着くスプリング (Animation.liquid)
LiquidView(animation: .smooth) { ... }

// センサー値に即時追従させる
LiquidView(animation: nil) { ... }

// センサー値そのものにローパスフィルタをかける (0...0.99)
LiquidView(smoothing: 0.8) { ... }
```

### 傾きを固定する(プレビュー・シミュレータ向け)

シミュレータでは CoreMotion が動かないため、`tilt` を直接渡せるイニシャライザを用意しています。

```swift
LiquidView(tilt: .degrees(30)) {
    Text("hoge")
}
```

### センサーを直接扱う

`LiquidMotion` は `@Observable` なモデルとして単体でも使えます。

```swift
@State private var motion = LiquidMotion()

var body: some View {
    Text("\(motion.tilt.degrees)°")
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
}
```

## 仕組み

1. `CMMotionManager` の `gravity` から端末の傾き φ を `atan2(gx, -gy)` で求める
2. `windowScene.interfaceOrientation` に応じて重力ベクトルを画面座標系へ変換する
3. ±180° をまたいでも逆回転しないよう角度をアンラップし、端末がほぼ水平のときは直前値を保持する
4. コンテンツを `-φ` 回転させ、サイズを容器の水平外接矩形
   `(w|cos φ| + h|sin φ|, w|sin φ| + h|cos φ|)` にして容器中心に置き、容器の枠でクリップする

幾何計算は `LiquidGeometry` に純粋関数として切り出してあり、Swift Testing でテストしています。

## テスト

パッケージは iOS 専用のため、シミュレータを指定して実行します。

```bash
xcodebuild test -scheme LiquidLevel -destination 'platform=iOS Simulator,name=iPhone 17'
```

## 補足

- CoreMotion の加速度・ジャイロは Info.plist の使用許可キー(`NSMotionUsageDescription`)を必要としません
- 実機でのみ傾きに追従します。シミュレータでは `tilt:` 付きイニシャライザで確認してください

## License

MIT
