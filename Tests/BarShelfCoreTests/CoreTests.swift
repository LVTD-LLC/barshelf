import XCTest
@testable import BarShelfCore

final class VisibilityModeTests: XCTestCase {
    func testLabelsMatchSettingsCopy() {
        XCTAssertEqual(VisibilityMode.alwaysShown.label, "Always shown")
        XCTAssertEqual(VisibilityMode.floatingShelf.label, "Floating shelf")
        XCTAssertEqual(VisibilityMode.alwaysHidden.label, "Always hidden")
    }

    func testAllModesAreAvailableInSettingsOrder() {
        XCTAssertEqual(VisibilityMode.allCases, [.alwaysShown, .floatingShelf, .alwaysHidden])
    }
}

final class MenuBarItemIdentityTests: XCTestCase {
    func testDisplayNameFallsBackToOwnerWhenWindowNameIsEmpty() {
        let identity = MenuBarItemIdentity(owner: "Dropbox", name: "", roundedX: 1170)

        XCTAssertEqual(identity.displayName, "Dropbox")
        XCTAssertEqual(identity.id, "Dropbox|status-item|1170")
    }

    func testDisplayNameIncludesOwnerAndWindowNameWhenAvailable() {
        let identity = MenuBarItemIdentity(owner: "Calendar", name: "Next Meeting", roundedX: 932)

        XCTAssertEqual(identity.displayName, "Calendar — Next Meeting")
        XCTAssertEqual(identity.id, "Calendar|Next Meeting|932")
    }
}

final class VisibilityModeCodecTests: XCTestCase {
    func testRoundTripPersistsPerItemModes() throws {
        let modes = [
            "Dropbox|status-item|1170": VisibilityMode.floatingShelf,
            "Calendar|Next Meeting|932": VisibilityMode.alwaysHidden
        ]

        let data = try VisibilityModeCodec.encode(modes)
        let decoded = VisibilityModeCodec.decode(data)

        XCTAssertEqual(decoded, modes)
    }

    func testDecodeHandlesMissingOrInvalidDataSafely() {
        XCTAssertEqual(VisibilityModeCodec.decode(nil), [:])
        XCTAssertEqual(VisibilityModeCodec.decode(Data("not-json".utf8)), [:])
    }

    func testDecodeDropsUnknownModesWithoutDroppingValidEntries() throws {
        let raw = [
            "valid": "floatingShelf",
            "future-mode": "shownOnHover"
        ]
        let data = try JSONEncoder().encode(raw)

        XCTAssertEqual(VisibilityModeCodec.decode(data), ["valid": .floatingShelf])
    }
}
