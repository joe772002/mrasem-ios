//
//  TestFlags.swift
//  WantProcuration
//
//  Temporary test switches (IOS_PORT_GUIDE.md §4.8 C). Debug builds only.
//  ⚠️ Remove this file (and its uses) before release.
//

#if DEBUG
enum TestFlags {
    /// true = an office opened normally in the booking form looks like it has no free days,
    /// so the "nearby offices" card appears. Offices opened from that card show their real days.
    static let simulateNoFreeDays = false
}
#endif
