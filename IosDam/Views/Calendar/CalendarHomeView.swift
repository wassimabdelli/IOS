//
//  CalendarHomeView.swift
//  IosDam
//
//  Created by Trae AI on 2024-12-06.
//

import SwiftUI

// MARK: - Design Colors
// ... (Color extension kept as is)
extension Color {
    static let softGreenBg = Color(red: 0.627, green: 0.847, blue: 0.702) // #A0D8B3
    static let mediumGreen = Color(red: 0.525, green: 0.784, blue: 0.604) // #86C89A
    static let darkGreenText = Color(red: 0.2, green: 0.4, blue: 0.25)
    static let inputBg = Color(red: 0.75, green: 0.9, blue: 0.8)
}

// MARK: - Models
struct CalendarEvent: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
    var description: String
    var color: Color = .mediumGreen
}

// MARK: - Main View
struct CalendarHomeView: View {
    @State private var selectedDate = Date()
    @State private var currentMonthOffset = 0
    @State private var showingAddEvent = false
    
    // Helper to get today's date stripped of time (midnight)
    private var todayMidnight: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    // Mock events - ensuring they are correctly placed ON TODAY
    @State private var events: [CalendarEvent] = [
        // Use todayMidnight as the base date for mock events
        CalendarEvent(title: "Examination", date: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Calendar.current.startOfDay(for: Date()))!, description: "Final Exam"),
        CalendarEvent(title: "Meeting at office", date: Calendar.current.date(bySettingHour: 11, minute: 30, second: 0, of: Calendar.current.startOfDay(for: Date()))!, description: "Project Sync"),
        CalendarEvent(title: "To do housework", date: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Calendar.current.startOfDay(for: Date()))!, description: "Cleaning")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.softGreenBg.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Custom Calendar
                    CustomCalendarView(selectedDate: $selectedDate, monthOffset: $currentMonthOffset)
                        .padding(.bottom, 20)
                    
                    // Content Sheet
                    VStack(alignment: .leading, spacing: 20) {
                        Text(isToday(selectedDate) ? "Today" : monthDayFormatter.string(from: selectedDate))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.mediumGreen)
                            .padding(.top, 30)
                            .padding(.horizontal, 30)
                        
                        // FIX: Ensure the filtering logic is robust
                        let daysEvents = events.filter { isSameDay($0.date, selectedDate) }
                        
                        if daysEvents.isEmpty {
                            EmptyStateView()
                        } else {
                            TimelineView(events: daysEvents)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.white
                            // NOTE: cornerRadius extension is defined elsewhere (EventComponents.swift)
                            .cornerRadius(40, corners: [.topLeft, .topRight])
                            .edgesIgnoringSafeArea(.bottom)
                    )
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddEvent = true }) {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.mediumGreen)
                                .cornerRadius(20)
                        }
                        .padding(30)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddEvent) {
                CalendarAddNoteView(isPresented: $showingAddEvent, events: $events, initialDate: selectedDate)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Helpers
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        // This is the core logic that determines if events are shown
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    private var monthDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }
}

// MARK: - Subviews

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var monthOffset: Int
    private let calendar = Calendar.current
    private let daysOfWeek = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    
    private var currentMonthDate: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Month/Year Header
            HStack {
                Button(action: {
                    monthOffset -= 1
                    // When month changes, update selectedDate to the first day of the new month
                    if let newDate = calendar.date(byAdding: .month, value: monthOffset, to: Date()),
                       let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newDate)) {
                        selectedDate = startOfMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.darkGreenText)
                        .padding(10)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(10)
                }
                Spacer()
                Text(monthYearFormatter.string(from: currentMonthDate))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    monthOffset += 1
                    // When month changes, update selectedDate to the first day of the new month
                    if let newDate = calendar.date(byAdding: .month, value: monthOffset, to: Date()),
                       let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newDate)) {
                        selectedDate = startOfMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.darkGreenText)
                        .padding(10)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            // Days of Week
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.darkGreenText.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            
            // Calendar Grid
            let days = fetchDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                ForEach(days, id: \.self) { date in
                    if calendar.isDate(date, equalTo: currentMonthDate, toGranularity: .month) {
                        DayCell(date: date, selectedDate: $selectedDate)
                    } else {
                        Text("")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    func fetchDays() -> [Date] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonthDate))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        // Calculate the weekday offset for the first day of the month
        let firstWeekday = (calendar.component(.weekday, from: startOfMonth) - calendar.firstWeekday + 7) % 7
        
        var days: [Date] = []
        for dayOffset in 0..<(range.count + firstWeekday) {
            if let date = calendar.date(byAdding: .day, value: dayOffset - firstWeekday, to: startOfMonth) {
                days.append(date)
            }
        }
        return days
    }
}

struct DayCell: View {
    let date: Date
    @Binding var selectedDate: Date
    private let calendar = Calendar.current
    
    // Check if the cell date is the same day as the globally selected date
    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    var body: some View {
        Text("\(calendar.component(.day, from: date))")
            .font(.headline)
            .fontWeight(isSelected ? .bold : .regular)
            .foregroundColor(isSelected ? .mediumGreen : .white)
            .frame(width: 35, height: 35)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.mediumGreen : Color.clear, lineWidth: 2)
            )
            .onTapGesture {
                selectedDate = date // Update the selected date on tap
            }
    }
}

struct TimelineView: View {
    let events: [CalendarEvent]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Sort events by time
                let sortedEvents = events.sorted(by: { $0.date < $1.date })
                
                ForEach(Array(sortedEvents.enumerated()), id: \.element.id) { index, event in
                    HStack(alignment: .top, spacing: 15) {
                        // Timeline line and dot
                        VStack(spacing: 0) {
                            Circle()
                                .fill(event.color) // Use event color
                                .frame(width: 10, height: 10)
                            if index < events.count - 1 {
                                Rectangle()
                                    .fill(event.color.opacity(0.3)) // Use event color
                                    .frame(width: 2)
                            }
                        }
                        .frame(width: 20)
                        
                        // Event Details
                        VStack(alignment: .leading, spacing: 5) {
                            Text(event.title)
                                .font(.headline)
                                .foregroundColor(.darkGreenText)
                            Text(event.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 25)
                    }
                }
            }
            .padding(.horizontal, 30)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Any")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
            Text("Event?")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            WavyShape()
                .fill(Color.mediumGreen)
                .frame(height: 120)
        }
        .frame(maxWidth: .infinity)
        .background(Color.softGreenBg.opacity(0.3))
    }
}

// MARK: - Utilities

struct WavyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.5))
        path.addCurve(to: CGPoint(x: rect.width, y: rect.height * 0.7),
                      control1: CGPoint(x: rect.width * 0.4, y: rect.height * 0.2),
                      control2: CGPoint(x: rect.width * 0.7, y: rect.height * 0.9))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}
