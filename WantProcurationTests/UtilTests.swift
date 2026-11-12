//
//  UtilTests.swift
//  WantProcurationTests
//
//  Mirrors Android: src/test/.../util/UtilTest.kt
//

import XCTest
@testable import WantProcuration

final class ContactLinksTests: XCTestCase {

    func testTelKeepsPlusAndDropsSpaces() {
        XCTAssertEqual(ContactLinks.tel("+974 5555 0123"), "tel:+97455550123")
    }

    func testWhatsAppUsesDigitsOnly() {
        XCTAssertEqual(ContactLinks.whatsApp("+974 5555 0123"), "https://wa.me/97455550123")
        XCTAssertEqual(ContactLinks.whatsApp("+44 (7700) 900-123"), "https://wa.me/447700900123")
    }

    func testMapsUrlHasCoordinates() {
        XCTAssertEqual(
            ContactLinks.maps(lat: 25.3226, lng: 51.5262),
            "https://www.google.com/maps/search/?api=1&query=25.3226,51.5262"
        )
    }
}

final class ArabicNumberTests: XCTestCase {

    func testDecimalHoursKeepPoint() {
        XCTAssertEqual(3.5.toArabicNumber(), "٣.٥")
        XCTAssertEqual(2.5.toArabicNumber(), "٢.٥")
    }

    func testWholeHoursHaveNoFraction() {
        XCTAssertEqual(3.0.toArabicNumber(), "٣")
        XCTAssertEqual(12.toArabicDigits(), "١٢")
    }

    func testRoomNumberConverts() {
        XCTAssertEqual("1204".toArabicDigits(), "١٢٠٤")
    }
}
