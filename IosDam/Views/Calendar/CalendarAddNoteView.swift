//
//  CalendarAddNoteView.swift
//  IosDam
//
//  Created by Trae AI on 2024-12-06.
//

import SwiftUI
import UIKit

struct CalendarAddNoteView: View {
    @Binding var isPresented: Bool
    @Binding var events: [CalendarEvent]
    var initialDate: Date
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedColor: Color = .mediumGreen
    @State private var hasAlarm = false
    
    // Picker states
    @State private var day: Int
    @State private var month: Int
    @State private var hour: Int
    @State private var minute: Int
    @State private var isPM: Bool
    
    private let calendar = Calendar.current
    private let colors: [Color] = [.mediumGreen, .red, .yellow, .blue]
    
    // MARK: Initialization and UIKit Fix
    init(isPresented: Binding<Bool>, events: Binding<[CalendarEvent]>, initialDate: Date) {
        _isPresented = isPresented
        _events = events
        self.initialDate = initialDate
        
        let calendar = Calendar.current
        _day = State(initialValue: calendar.component(.day, from: initialDate))
        _month = State(initialValue: calendar.component(.month, from: initialDate))
        let h = calendar.component(.hour, from: initialDate)
        // 12-hour format logic for initial state
        _hour = State(initialValue: h > 12 ? h - 12 : (h == 0 ? 12 : h))
        _minute = State(initialValue: calendar.component(.minute, from: initialDate))
        _isPM = State(initialValue: h >= 12)
        
        // Fix for TextEditor background issue in iOS 14 sheets
        UITextView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.softGreenBg.edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 0) {
                // Header (Close Button & Title)
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                Text("Add notes")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                
                // Main Content Card
                VStack(spacing: 0) {
                    // --- 1. Date and Time Picker (Moved out of ScrollView) ---
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Date and Time:")
                            .font(.headline)
                            .foregroundColor(.mediumGreen)
                        
                        HStack(spacing: 0) {
                            // Explicitly setting frame width for consistent column layout
                            CustomPicker(selection: $day, range: 1...31, label: "Day").frame(width: 65)
                            CustomPicker(selection: $month, range: 1...12, label: "Month").frame(width: 70)
                            CustomPicker(selection: $hour, range: 1...12, label: "Hour").frame(width: 65)
                            CustomPicker(selection: $minute, range: 0...59, label: "Minute").frame(width: 65)
                            AmPmPicker(isPM: $isPM).frame(width: 35)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            
                            // --- 2. Title Input ---
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Title:")
                                    .font(.headline)
                                    .foregroundColor(.mediumGreen)
                                
                                // Replicating the rounded input style
                                TextField("", text: $title)
                                    .padding()
                                    .background(Color.inputBg)
                                    .cornerRadius(20)
                            }
                            
                            // --- 3. Notes Input ---
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Notes:")
                                    .font(.headline)
                                    .foregroundColor(.mediumGreen)
                                
                                // Replicating the rounded input style
                                TextEditor(text: $description)
                                    .frame(height: 150)
                                    .padding()
                                    .background(Color.inputBg)
                                    .cornerRadius(20)
                            }
                            
                            // --- 4. Color and Alarm Options ---
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Color")
                                        .font(.subheadline)
                                        .foregroundColor(.mediumGreen)
                                    HStack {
                                        ForEach(colors, id: \.self) { color in
                                            Circle()
                                                .fill(color)
                                                .frame(width: 25, height: 25)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                                )
                                                .onTapGesture { selectedColor = color }
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text("Alarm")
                                        .font(.subheadline)
                                        .foregroundColor(.mediumGreen)
                                    Toggle("", isOn: $hasAlarm)
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle())
                                        .accentColor(.mediumGreen)
                                }
                            }
                            
                            // --- 5. Save Button ---
                            Button(action: saveEvent) {
                                Text("Save")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.mediumGreen)
                                    .cornerRadius(20)
                            }
                            .padding(.top, 20)
                        }
                        .padding(30)
                        .padding(.bottom, 50) // Ensure button is not cut off
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensures the card takes available space
                .background(
                    Color.white
                        .cornerRadius(40, corners: [.topLeft, .topRight])
                        .edgesIgnoringSafeArea(.bottom)
                )
            }
        }
    }
    
    func saveEvent() {
        guard !title.isEmpty else { return }
        
        var dateComponents = DateComponents()
        dateComponents.year = calendar.component(.year, from: initialDate)
        dateComponents.month = month
        dateComponents.day = day
        // Convert 12-hour format back to 24-hour format
        dateComponents.hour = isPM ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour)
        dateComponents.minute = minute
        
        if let eventDate = calendar.date(from: dateComponents) {
            let newEvent = CalendarEvent(title: title, date: eventDate, description: description, color: selectedColor)
            events.append(newEvent)
            isPresented = false
        }
    }
}

// MARK: - Custom Pickers (Fixed with UIKit)

struct CustomPicker: View {
    @Binding var selection: Int
    let range: ClosedRange<Int>
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.mediumGreen)
            
            // Using UIKit wrapper to avoid ScrollView conflicts and width issues
            WheelPicker(selection: $selection, range: range)
                .frame(height: 100)
                .background(Color.inputBg.opacity(0.5))
                .cornerRadius(10)
        }
    }
}

struct AmPmPicker: View {
    @Binding var isPM: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Text("") // Placeholder
                .font(.caption)
            
            // Using UIKit wrapper
            AmPmWheelPicker(isPM: $isPM)
                .frame(height: 100)
                .background(Color.inputBg.opacity(0.5))
                .cornerRadius(10)
        }
    }
}

// MARK: - UIKit Picker Wrappers

struct WheelPicker: UIViewRepresentable {
    @Binding var selection: Int
    let range: ClosedRange<Int>
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.backgroundColor = .clear
        return picker
    }
    
    func updateUIView(_ picker: UIPickerView, context: Context) {
        let row = selection - range.lowerBound
        if picker.selectedRow(inComponent: 0) != row {
            picker.selectRow(row, inComponent: 0, animated: false)
        }
    }
    
    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: WheelPicker
        
        init(_ parent: WheelPicker) {
            self.parent = parent
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            parent.range.count
        }
        
        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = UILabel()
            label.text = String(format: "%02d", parent.range.lowerBound + row)
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 20, weight: .bold)
            label.backgroundColor = .clear
            return label
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            parent.selection = parent.range.lowerBound + row
        }
    }
}

struct AmPmWheelPicker: UIViewRepresentable {
    @Binding var isPM: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.backgroundColor = .clear
        return picker
    }
    
    func updateUIView(_ picker: UIPickerView, context: Context) {
        let row = isPM ? 1 : 0
        if picker.selectedRow(inComponent: 0) != row {
            picker.selectRow(row, inComponent: 0, animated: false)
        }
    }
    
    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: AmPmWheelPicker
        
        init(_ parent: AmPmWheelPicker) {
            self.parent = parent
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { 2 }
        
        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = UILabel()
            label.text = row == 0 ? "AM" : "PM"
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 20, weight: .bold)
            label.backgroundColor = .clear
            return label
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            parent.isPM = (row == 1)
        }
    }
}
