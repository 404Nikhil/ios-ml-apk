//
//  FilterOption.swift
//  WSHackathonApp
//

import Foundation

enum FilterType: String, Codable {
    case category
    case price
    case attribute
}

struct FilterOption: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let type: FilterType
}

struct SmartFilterResponse: Codable {
    let suggestedFilters: [FilterOption]
}
