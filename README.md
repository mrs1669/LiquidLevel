# LiquidLevel

**日本語** | [English](README_EN.md)

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

// 容器の面積の 40% の液体が、水平な液面で底に溜まる
LiquidView(contentMode: .waterline(0.4)) {
    Color.blue
}
```

`.waterline` では、コンテンツに「液面より下の領域」を覆う水平矩形が与えられます
(幅は水平外接矩形と同じ、高さは水位)。`alignment: .top` にすると液面に沿ったレイアウトになります。
割合を `@State` に結びつければ、水位の変化もアニメーションします。

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

### センサーを直接扱う・共有する

`LiquidMotion` は `@Observable` なモデルとして単体でも使えます。
`LiquidView(motion:)` に渡せば、複数の View でセンサーを共有したり、傾きの値を別の UI に表示できます
(この場合 `start()` / `stop()` は呼び出し側で行います)。

```swift
@State private var motion = LiquidMotion()

var body: some View {
    VStack {
        LiquidView(motion: motion) { Color.blue }
        Text("\(motion.tilt.degrees)°")
    }
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
   - `.fit` は同じ不等式を逆に解き、内接する最大の水平矩形を求める
   - `.waterline` は傾いた矩形の「高さ y 以下の面積」を区分関数として閉形式で逆算し、水位を求める

幾何計算は `LiquidGeometry` に純粋関数として切り出してあり、Swift Testing でテストしています。

## テスト

パッケージは iOS 専用のため、シミュレータを指定して実行します。

```bash
xcodebuild test -scheme LiquidLevel -destination 'platform=iOS Simulator,name=iPhone 17'
```

## デモアプリ

`Example/LiquidLevelExample.xcodeproj` を開いて実機で実行すると、傾き・インターフェース向きの読み出し、
モード切り替え、手動 tilt の Slider で挙動を確認できます(シミュレータでは CoreMotion が動かないため手動 tilt で確認してください)。
プロジェクトは [XcodeGen](https://github.com/yonaskolb/XcodeGen) で生成しています。構成を変えた場合は再生成してください。

```bash
cd Example && xcodegen generate
```

## 補足

- CoreMotion の加速度・ジャイロは Info.plist の使用許可キー(`NSMotionUsageDescription`)を必要としません
- 実機でのみ傾きに追従します。シミュレータでは `tilt:` 付きイニシャライザで確認してください

## License

MIT
