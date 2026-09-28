//
//  Performance.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 28/07/26.
//

import Foundation
import SwiftUI
import Combine
import MachO
import Darwin

final class PerformanceMonitor: ObservableObject {

    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: Double = 0

    private var timer: AnyCancellable?

    init() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cpuUsage = Self.cpu()
                self?.memoryUsage = Self.memory()
            }
    }

    deinit {
        timer?.cancel()
    }

    // MARK: CPU

    static func cpu() -> Double {

        var threads: thread_act_array_t?
        var threadCount = mach_msg_type_number_t()

        guard task_threads(
            mach_task_self_,
            &threads,
            &threadCount
        ) == KERN_SUCCESS,
              let threads else {
            return 0
        }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: threads)),
                vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.stride)
            )
        }

        var total: Double = 0

        for i in 0..<Int(threadCount) {

            var info = thread_basic_info()
            var count = mach_msg_type_number_t(THREAD_INFO_MAX)

            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    thread_info(
                        threads[i],
                        thread_flavor_t(THREAD_BASIC_INFO),
                        $0,
                        &count
                    )
                }
            }

            if result == KERN_SUCCESS,
               (info.flags & TH_FLAGS_IDLE) == 0 {

                total += Double(info.cpu_usage) /
                    Double(TH_USAGE_SCALE) * 100
            }
        }

        return total
    }

    // MARK: Memory

    static func memory() -> Double {

        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
        )

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        return Double(info.resident_size) / 1024 / 1024
    }
}

import SwiftUI

struct MeterBar: View {

    let value: Double
    let maxValue: Double

    var body: some View {

        GeometryReader { geo in

            ZStack(alignment: .leading) {

                Capsule()
                    .fill(.gray.opacity(0.25))

                Capsule()
                    .fill(barColor)
                    .frame(width: geo.size.width *
                        CGFloat(min(value / maxValue, 1)))
            }
        }
        .frame(height: 8)
    }

    var barColor: Color {

        switch value / maxValue {
        case ..<0.5:
            return .green
        case ..<0.8:
            return .yellow
        default:
            return .red
        }
    }
}

import SwiftUI

struct PerformanceOverlay: View {

    @StateObject private var monitor = PerformanceMonitor()

    var body: some View {

        VStack(spacing: 8) {

            HStack {
                Image(systemName: "cpu")
                Text(String(format: "%.1f%%", monitor.cpuUsage))
                Spacer()
            }

            MeterBar(
                value: monitor.cpuUsage,
                maxValue: 100
            )

            HStack {
                Image(systemName: "memorychip")
                Text(String(format: "%.1f MB", monitor.memoryUsage))
                Spacer()
            }

            MeterBar(
                value: monitor.memoryUsage,
                maxValue: 60 // adjust for your app
            )
        }
        .padding(10)
        .background(.black.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ZStack {

        ContentView()

        VStack {
            PerformanceOverlay()
            Spacer()
        }
    }
}
