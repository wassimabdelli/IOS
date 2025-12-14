//
//  CalendarEventDetailView.swift
//  IosDam
//
//  Created by Trae AI on 2024-12-06.
//

import SwiftUI

struct CalendarEventDetailView: View {
    let event: CalendarEvent
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.softGreenBg.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Nav Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                    }
                    Spacer()
                    Text("Event Details")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    // Balance view
                    Image(systemName: "chevron.left").opacity(0).padding(10)
                }
                .padding()
                .padding(.top, 10)
                
                // Main Content Card
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Title and Date
                        VStack(alignment: .leading, spacing: 5) {
                            Text(event.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                // Use the event's color for the title
                                .foregroundColor(event.color)
                            
                            Text(dayFormatter.string(from: event.date))
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        
                        // Time Card
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "clock.fill")
                                .font(.title2)
                                // Use the event's color for the icon
                                .foregroundColor(event.color)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Time")
                                    .font(.headline)
                                    .foregroundColor(Color.darkGreenText)
                                Text(timeFormatter.string(from: event.date))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Use a lighter tint of the event's color for the background
                        .background(event.color.opacity(0.1))
                        .cornerRadius(20)
                        
                        // Description Card
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "text.alignleft")
                                .font(.title2)
                                // Use the event's color for the icon
                                .foregroundColor(event.color)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(Color.darkGreenText)
                                Text(event.description)
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Use a lighter tint of the event's color for the background
                        .background(event.color.opacity(0.1))
                        .cornerRadius(20)
                        
                        Spacer()
                    }
                    .padding(30)
                }
                .frame(maxWidth: .infinity)
                .background(
                    Color.white
                        .cornerRadius(40, corners: [.topLeft, .topRight])
                        .edgesIgnoringSafeArea(.bottom)
                )
            }
        }
        .navigationBarHidden(true)
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}
