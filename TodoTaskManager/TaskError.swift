//
//  TaskError.swift
//  TodoTaskManager
//
//  Created by Wojtek on 30/07/2026.
//

import Foundation

enum TaskError: Error {
    case noConnection
    case badUrl(url: String)
    case timeout
    case invalidResponse(body: String)
    case serverError(statusCode: Int)
    case decodingFailed
    case unknown(Error)
}

extension TaskError {
    var userMessage: String {
        switch self {
        case .noConnection:
            return "No internet connection. Check your network and try again."
        case .badUrl:
            return "Something went wrong. Please try again later."
        case .timeout:
            return "Connection timed out. Please try again."
        case .invalidResponse:
            return "Something went wrong. Please try again later."
        case .serverError:
            return "Service is temporarily unavailable. Please try again later."
        case .decodingFailed:
            return "Something went wrong. Please try again later."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var developerLog: String {
        switch self {
            case .noConnection:
                return "No internet connection"
            case .badUrl(url: let url):
                return "Invalid URL: \(url)"
            case .timeout:
                return "Request timed out"
            case .invalidResponse(body: let body):
                return "Invalid response from server. Response body: \(body)"
            case .serverError(statusCode: let statusCode):
                return "Server returned error with status code: \(statusCode)"
            case .decodingFailed:
                return "JSON decoding failed — model may not match API response structure"
            case .unknown(let error):
                return "Unknown error: \(error.localizedDescription)"
        }
    }
}
