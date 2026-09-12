import XCTest
@testable import NanoBuddha

final class SitRequestTests: XCTestCase {
    private var fileURL: URL!

    override func setUp() {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("sitRequest-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testTakeConsumesTheRequestOnce() {
        SitRequest.post(fileURL: fileURL)
        XCTAssertTrue(SitRequest.take(fileURL: fileURL))
        XCTAssertFalse(SitRequest.take(fileURL: fileURL))
    }

    func testStaleRequestIsIgnored() {
        SitRequest.post(now: .now.addingTimeInterval(-120), fileURL: fileURL)
        XCTAssertFalse(SitRequest.take(fileURL: fileURL))
    }

    func testNothingPostedIsFalse() {
        XCTAssertFalse(SitRequest.take(fileURL: fileURL))
    }
}
