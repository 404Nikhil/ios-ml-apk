//
//  AppConstants.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
enum AppConstants {
    
    enum API {
        static let baseURL = "http://127.0.0.1:8000"
        static let imageBasePath = baseURL
        static let timeout: TimeInterval = 30
    }

    enum RecommendAPI {
        static let baseURL = API.baseURL
        static let recommendEndpoint = baseURL + "/recommend"
    }
}
