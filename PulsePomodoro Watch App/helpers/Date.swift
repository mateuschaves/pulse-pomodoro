//
//  Date.swift
//  PulsePomodoro
//
//  Created by Mateus Henrique on 19/11/24.
//
import Foundation

func formatRelativeTime(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
}

func formatSecondsToMMSS(seconds: Int) -> String {
    let minutes = seconds / 60
    let seconds = seconds % 60
    return String(format: "%02d:%02d", minutes, seconds)
}
