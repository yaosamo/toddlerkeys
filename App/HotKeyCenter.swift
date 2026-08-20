import Carbon
import Foundation

final class HotKeyCenter {
    var onPressed: ((GlobalHotKeyAction) -> Void)?

    private var hotKeyRefs: [EventHotKeyRef] = []
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

        for descriptor in GlobalHotKeys.all {
            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: fourCharCode("TKEY"), id: descriptor.id)
            let hotKeyStatus = RegisterEventHotKey(
                descriptor.keyCode,
                descriptor.carbonModifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
            if hotKeyStatus == noErr, let hotKeyRef {
                hotKeyRefs.append(hotKeyRef)
            } else {
                print("Mr.Blobsky: RegisterEventHotKey \(descriptor.displayName) failed (\(hotKeyStatus))")
            }
        }
    }

    func unregister() {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    func invoke(id: UInt32) {
        guard let action = GlobalHotKeys.descriptor(id: id)?.action else { return }
        if Thread.isMainThread {
            onPressed?(action)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onPressed?(action)
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
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr, hotKeyID.signature == fourCharCode("TKEY") else {
        return OSStatus(eventNotHandledErr)
    }
    Unmanaged<HotKeyCenter>.fromOpaque(userData).takeUnretainedValue().invoke(id: hotKeyID.id)
    return noErr
}
