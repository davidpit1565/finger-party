import SwiftUI
import UIKit
import FingerPickerCore

/// UIKit surface that receives the raw multi-touch stream. Only `(TouchID, NormalizedPoint)` values
/// leave this class; UITouch objects are never retained beyond the map keys' lifetime.
final class TouchCaptureUIView: UIView {
    weak var model: TouchSessionModel?

    /// Never-reused, monotonically increasing ids (static so a re-created view cannot alias old ids).
    private static var nextRawID = 1000
    private var activeTouches: [ObjectIdentifier: TouchID] = [:]
    private var lastBoundsSize: CGSize = .zero
    private var invalidationScheduled = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        isExclusiveTouch = false
        backgroundColor = .clear
        isOpaque = false
        // One element that VoiceOver users can interact with directly.
        isAccessibilityElement = true
        accessibilityTraits = .allowsDirectInteraction
        accessibilityLabel = "Play area"
        accessibilityHint = "Place two or more fingers on the screen to pick one at random"
        accessibilityIdentifier = "touchSurface"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: Layout / lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        // Ignore transient zero-size layouts so they cannot be mistaken for a rotation.
        guard bounds.size != .zero, bounds.size != lastBoundsSize else { return }
        let hadSize = lastBoundsSize != .zero
        lastBoundsSize = bounds.size
        if hadSize { invalidate() }   // rotation / resize: old coordinates are meaningless
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { invalidate() }
    }

    /// Forget every tracked touch and tell the model to drop the round.
    private func invalidate() {
        activeTouches.removeAll()
        guard !invalidationScheduled else { return }
        invalidationScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.invalidationScheduled = false
            self.model?.interrupt()
        }
    }

    // MARK: Touches

    private func normalized(_ touch: UITouch) -> NormalizedPoint {
        let p = touch.location(in: self)
        return RevealGeometry.normalize(x: Double(p.x), y: Double(p.y),
                                        width: Double(bounds.width), height: Double(bounds.height))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches where touch.type == .direct {
            let key = ObjectIdentifier(touch)
            if let staleID = activeTouches.removeValue(forKey: key) {
                model?.touchCancelled(staleID)
            }
            let id = TouchID(Self.nextRawID)
            Self.nextRawID += 1
            activeTouches[key] = id
            model?.touchBegan(id, at: normalized(touch))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let id = activeTouches[ObjectIdentifier(touch)] else { continue }
            model?.touchMoved(id, to: normalized(touch))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let id = activeTouches.removeValue(forKey: ObjectIdentifier(touch)) else { continue }
            model?.touchEnded(id)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let id = activeTouches.removeValue(forKey: ObjectIdentifier(touch)) else { continue }
            model?.touchCancelled(id)
        }
    }
}

struct TouchCaptureView: UIViewRepresentable {
    let model: TouchSessionModel

    func makeUIView(context: Context) -> TouchCaptureUIView {
        let view = TouchCaptureUIView()
        view.model = model
        return view
    }

    func updateUIView(_ uiView: TouchCaptureUIView, context: Context) {
        uiView.model = model
    }
}
