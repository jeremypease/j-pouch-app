import Foundation

/// Fixed UTC calendar and reference date so tests never depend on the machine's timezone
/// or the wall clock.
let testCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

let testToday = testCalendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))

func testDaysAgo(_ offset: Int) -> Date {
    testCalendar.date(byAdding: .day, value: -offset, to: testToday)!
}
