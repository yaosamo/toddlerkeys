import Carbon
import Foundation

final class HotKeyCenter {
    var onPressed: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func register() {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let installed = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &handlerRef
        )
        guard installed == noErr else { return }

        var hotKeyID = EventHotKeyID(signature: fourCharCode("TKEY"), id: 1)
        let hotKeyStatus = RegisterEventHotKey(
            ToggleHotKey.keyCode,
            ToggleHotKey.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if hotKeyStatus != noErr {
            print("Mr.Blobsky: RegisterEventHotKey failed (\(hotKeyStatus))")
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    fileprivate func invoke() {
        if Thread.isMainThread {
            onPressed?()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onPressed?()
            }
        }
    }

    deinit {
        unregister()
    }
}

private func fourCharCode(_ string: String) -> OSType {
    var result: OSType = 0
    for byte in string.utf8.prefix(4) {
        result = (result << 8) + OSType(byte)
    }
    return result
}

private func hotKeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return noErr }
    Unmanaged<HotKeyCenter>.fromOpaque(userData).takeUnretainedValue().invoke()
    return noErr
}
