import AppKit
import Carbon.HIToolbox

final class GlobalShortcutManager: @unchecked Sendable {
    var onPressed: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var current: KeyChord?
    private(set) var lastRegistrationFailed = false

    private static let signature: OSType = 0x414E474C
    private static let hotKeyID: UInt32 = 1

    func register(_ chord: KeyChord) -> Bool {
        unregister()
        current = chord

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let userData = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            aangilamHotKeyHandler,
            1,
            &eventType,
            userData,
            &handlerRef
        )
        guard installStatus == noErr else {
            lastRegistrationFailed = true
            return false
        }

        var hotKeyID = EventHotKeyID(signature: Self.signature, id: Self.hotKeyID)
        let status = RegisterEventHotKey(
            chord.keyCode,
            chord.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        lastRegistrationFailed = status != noErr
        return status == noErr
    }

    fileprivate func handleHotKey() {
        onPressed?()
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
        lastRegistrationFailed = false
    }
}

private func aangilamHotKeyHandler(
    _ callRef: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData, let event else { return noErr }
    var hotKeyID = EventHotKeyID()
    GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard hotKeyID.signature == 0x414E474C else { return noErr }
    let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        manager.handleHotKey()
    }
    return noErr
}
