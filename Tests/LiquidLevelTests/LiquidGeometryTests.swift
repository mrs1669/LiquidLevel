import Foundation
import Testing
@testable import LiquidLevel

@Suite("LiquidGeometry")
struct LiquidGeometryTests {
    private let tolerance = 1e-9

    @Test("直立時の傾きは 0")
    func uprightTilt() throws {
        let tilt = try #require(LiquidGeometry.tilt(gravityX: 0, gravityY: -1))
        #expect(abs(tilt) < tolerance)
    }

    @Test("時計回りに 90° 回すと +π/2、反時計回りは -π/2")
    func quarterTurns() throws {
        let clockwise = try #require(LiquidGeometry.tilt(gravityX: 1, gravityY: 0))
        let counterClockwise = try #require(LiquidGeometry.tilt(gravityX: -1, gravityY: 0))
        #expect(abs(clockwise - .pi / 2) < tolerance)
        #expect(abs(counterClockwise + .pi / 2) < tolerance)
    }

    @Test("端末がほぼ水平なら傾きは nil")
    func flatDeviceReturnsNil() {
        #expect(LiquidGeometry.tilt(gravityX: 0.05, gravityY: -0.05) == nil)
    }

    @Test("±π をまたいでも角度が連続する")
    func unwrapAcrossPi() {
        let previous = Double.pi - 0.1
        let raw = -Double.pi + 0.1
        let unwrapped = LiquidGeometry.unwrapped(raw, previous: previous)
        #expect(abs(unwrapped - (Double.pi + 0.1)) < tolerance)

        let back = LiquidGeometry.unwrapped(previous, previous: unwrapped)
        #expect(abs(back - previous) < tolerance)
    }

    @Test("何周も回った後でも最短差分で追従する")
    func unwrapAfterMultipleTurns() {
        let previous = 4 * Double.pi + 0.2
        let unwrapped = LiquidGeometry.unwrapped(0.3, previous: previous)
        #expect(abs(unwrapped - (4 * Double.pi + 0.3)) < tolerance)
    }

    @Test("傾き 0 なら外接矩形は容器と同じ")
    func boundingBoxAtZero() {
        let box = LiquidGeometry.levelBoundingBox(containerSize: CGSize(width: 100, height: 200), tilt: 0)
        #expect(abs(box.width - 100) < tolerance)
        #expect(abs(box.height - 200) < tolerance)
    }

    @Test("傾き 90° なら幅と高さが入れ替わる")
    func boundingBoxAtQuarterTurn() {
        let box = LiquidGeometry.levelBoundingBox(containerSize: CGSize(width: 100, height: 200), tilt: .pi / 2)
        #expect(abs(box.width - 200) < tolerance)
        #expect(abs(box.height - 100) < tolerance)
    }

    @Test("正方形を 45° 傾けると対角線の長さになる(菱形の最下点まで届く)")
    func boundingBoxSquareAtDiagonal() {
        let box = LiquidGeometry.levelBoundingBox(containerSize: CGSize(width: 100, height: 100), tilt: .pi / 4)
        let diagonal = 100 * sqrt(2.0)
        #expect(abs(box.width - diagonal) < 1e-9)
        #expect(abs(box.height - diagonal) < 1e-9)
    }

    @Test("fit: 傾き 0 なら容器と同じサイズ")
    func fittedSizeAtZero() {
        let size = LiquidGeometry.fittedSize(containerSize: CGSize(width: 100, height: 200), tilt: 0)
        #expect(abs(size.width - 100) < tolerance)
        #expect(abs(size.height - 200) < tolerance)
    }

    @Test("fit: 傾き 90° では回転後の短辺に高さが揃う")
    func fittedSizeAtQuarterTurn() {
        // 100×200 を 90° 回すと 200×100 の枡になる。1:2 の矩形を収めると高さ 100 が上限
        let size = LiquidGeometry.fittedSize(containerSize: CGSize(width: 100, height: 200), tilt: .pi / 2)
        #expect(abs(size.width - 50) < tolerance)
        #expect(abs(size.height - 100) < tolerance)
    }

    @Test("fit: 正方形を 45° 傾けると 1/√2 の正方形が内接する")
    func fittedSizeSquareAtDiagonal() {
        let size = LiquidGeometry.fittedSize(containerSize: CGSize(width: 100, height: 100), tilt: .pi / 4)
        let expected = 100 / sqrt(2.0)
        #expect(abs(size.width - expected) < 1e-9)
        #expect(abs(size.height - expected) < 1e-9)
    }

    @Test("fit: 内接矩形の四隅が回転後の容器に収まる", arguments: [0.1, 0.4, 1.0, 2.0, 2.9])
    func fittedSizeStaysInside(tilt: Double) {
        let container = CGSize(width: 120, height: 300)
        let size = LiquidGeometry.fittedSize(containerSize: container, tilt: tilt)
        // 四隅を容器のローカル座標(+tilt 回転)に戻し、容器の半サイズ以内か確認
        for sx in [-1.0, 1.0] {
            for sy in [-1.0, 1.0] {
                let x = sx * size.width / 2
                let y = sy * size.height / 2
                let localX = x * cos(tilt) + y * sin(tilt)
                let localY = -x * sin(tilt) + y * cos(tilt)
                #expect(abs(localX) <= container.width / 2 + 1e-9)
                #expect(abs(localY) <= container.height / 2 + 1e-9)
            }
        }
    }

    @Test("layout: fill と fit はオフセットなし")
    func layoutFillAndFitHaveNoOffset() {
        let container = CGSize(width: 100, height: 200)
        let fill = LiquidGeometry.layout(containerSize: container, tilt: 0.7, mode: .fill)
        let fit = LiquidGeometry.layout(containerSize: container, tilt: 0.7, mode: .fit)
        #expect(fill.offset == .zero)
        #expect(fit.offset == .zero)
        #expect(fill.size == LiquidGeometry.levelBoundingBox(containerSize: container, tilt: 0.7))
        #expect(fit.size == LiquidGeometry.fittedSize(containerSize: container, tilt: 0.7))
    }

    @Test("waterline: 割合 0 と 1 で最下点と最上点になる")
    func waterlineExtremes() {
        let container = CGSize(width: 100, height: 200)
        let tilt = 0.6
        let total = LiquidGeometry.levelBoundingBox(containerSize: container, tilt: tilt).height
        #expect(abs(LiquidGeometry.waterlineHeight(containerSize: container, tilt: tilt, fraction: 0)) < tolerance)
        #expect(abs(LiquidGeometry.waterlineHeight(containerSize: container, tilt: tilt, fraction: 1) - total) < 1e-9)
        // 範囲外はクランプされる
        #expect(abs(LiquidGeometry.waterlineHeight(containerSize: container, tilt: tilt, fraction: 1.5) - total) < 1e-9)
    }

    @Test("waterline: 傾き 0 では水位が高さに比例する")
    func waterlineAtZeroTilt() {
        let height = LiquidGeometry.waterlineHeight(containerSize: CGSize(width: 100, height: 200), tilt: 0, fraction: 0.3)
        #expect(abs(height - 60) < tolerance)
    }

    @Test("waterline: 傾き 90° では回転後の高さ(元の幅)に比例する")
    func waterlineAtQuarterTurn() {
        let height = LiquidGeometry.waterlineHeight(containerSize: CGSize(width: 100, height: 200), tilt: .pi / 2, fraction: 0.3)
        #expect(abs(height - 30) < 1e-9)
    }

    @Test("waterline: 45° の正方形(菱形)は下半分が三角形になる")
    func waterlineSquareAtDiagonal() {
        let container = CGSize(width: 100, height: 100)
        let tilt = Double.pi / 4
        let total = 100 * sqrt(2.0)
        // 半分でちょうど菱形の中心
        #expect(abs(LiquidGeometry.waterlineHeight(containerSize: container, tilt: tilt, fraction: 0.5) - total / 2) < 1e-9)
        // 1/4 のとき: 三角形の面積 y²/(2sc) = 2500, sc = 0.5 → y = 50
        #expect(abs(LiquidGeometry.waterlineHeight(containerSize: container, tilt: tilt, fraction: 0.25) - 50) < 1e-9)
    }

    @Test("waterline: 区分の境界で連続する")
    func waterlineIsContinuousAtBoundaries() {
        let container = CGSize(width: 100, height: 200)
        let tilt = Double.pi / 6 // s = 0.5, c = √3/2
        let s = sin(tilt), c = cos(tilt)
        let m = min(container.width * s, container.height * c) // = 50
        let total = container.width * s + container.height * c
        let triangleArea = m * m / (2 * s * c)
        let totalArea = container.width * container.height

        let lower = LiquidGeometry.waterlineHeight(containerSize: container, tilt: tilt, fraction: triangleArea / totalArea)
        let upper = LiquidGeometry.waterlineHeight(containerSize: container, tilt: tilt, fraction: 1 - triangleArea / totalArea)
        #expect(abs(lower - m) < 1e-9)
        #expect(abs(upper - (total - m)) < 1e-9)
    }

    @Test("waterline: 割合に対して単調増加", arguments: [0.0, 0.3, 0.5, 1.0, 1.2, 2.0, 3.0])
    func waterlineIsMonotonic(tilt: Double) {
        let container = CGSize(width: 90, height: 160)
        var previous = -1.0
        for step in 0...20 {
            let height = LiquidGeometry.waterlineHeight(containerSize: container, tilt: tilt, fraction: Double(step) / 20)
            #expect(height > previous, "tilt=\(tilt) step=\(step)")
            previous = height
        }
    }

    @Test("layout: waterline は下辺が最下点に一致するようオフセットされる")
    func layoutWaterlineOffset() {
        let container = CGSize(width: 100, height: 200)

        // 傾き 0: 液体の高さ 60、中心は容器中心から下へ (200 - 60) / 2 = 70
        let upright = LiquidGeometry.layout(containerSize: container, tilt: 0, mode: .waterline(0.3))
        #expect(abs(upright.size.width - 100) < tolerance)
        #expect(abs(upright.size.height - 60) < tolerance)
        #expect(abs(upright.offset.width) < tolerance)
        #expect(abs(upright.offset.height - 70) < tolerance)

        // 時計回りに 90°: 画面の右が下。液体の高さ 30、中心は右へ (100 - 30) / 2 = 35
        let quarter = LiquidGeometry.layout(containerSize: container, tilt: .pi / 2, mode: .waterline(0.3))
        #expect(abs(quarter.size.width - 200) < 1e-9)
        #expect(abs(quarter.size.height - 30) < 1e-9)
        #expect(abs(quarter.offset.width - 35) < 1e-9)
        #expect(abs(quarter.offset.height) < 1e-9)
    }

    @Test("インターフェース向きごとに重力を変換すると直立状態になる")
    func gravityInInterfaceUpright() {
        // 各向きで端末を実際にその向きに持ったときのデバイス座標系の重力
        let cases: [(LiquidInterfaceOrientation, Double, Double)] = [
            (.portrait, 0, -1),
            (.portraitUpsideDown, 0, 1),
            (.landscapeLeft, 1, 0),   // 時計回りに 90°: デバイスの +x が下を向く
            (.landscapeRight, -1, 0), // 反時計回りに 90°: デバイスの -x が下を向く
        ]
        for (orientation, gx, gy) in cases {
            let g = LiquidGeometry.gravityInInterface(x: gx, y: gy, orientation: orientation)
            #expect(abs(g.x) < tolerance, "\(orientation)")
            #expect(abs(g.y + 1) < tolerance, "\(orientation)")
        }
    }
}

@Suite("LiquidMotion")
@MainActor
struct LiquidMotionTests {
    @Test("手動更新で傾きが反映される")
    func manualUpdate() {
        let motion = LiquidMotion()
        motion.update(gravityX: 1, gravityY: 0)
        #expect(abs(motion.tilt.radians - .pi / 2) < 1e-9)
    }

    @Test("端末が水平なら直前の傾きを保持する")
    func holdsTiltWhenFlat() {
        let motion = LiquidMotion()
        motion.update(gravityX: 1, gravityY: 0)
        motion.update(gravityX: 0.01, gravityY: 0.01)
        #expect(abs(motion.tilt.radians - .pi / 2) < 1e-9)
    }

    @Test("smoothing を指定すると目標値へ徐々に近づく")
    func smoothingApproachesTarget() {
        let motion = LiquidMotion(smoothing: 0.5)
        motion.update(gravityX: 1, gravityY: 0)
        #expect(abs(motion.tilt.radians - .pi / 4) < 1e-9)
        motion.update(gravityX: 1, gravityY: 0)
        #expect(abs(motion.tilt.radians - 3 * .pi / 8) < 1e-9)
    }
}
