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
