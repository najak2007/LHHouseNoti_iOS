//
//  FirestoreRESTClient.swift
//  LHHouseNoti
//
//  Created by najak on 6/24/26.
//

import Foundation
import FirebaseAuth

class FirestoreRESTClient {
    
    let baseURL = "https://firestore.googleapis.com/v1/projects/lhhousenoti/databases/(default)/documents"
    
    // MARK: - 공통 토큰 획득
    private func getToken() async throws -> String {
        if Auth.auth().currentUser == nil {
            try await Auth.auth().signInAnonymously()
        }
        
        guard let user = Auth.auth().currentUser else {
            throw URLError(.userAuthenticationRequired)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            user.getIDToken { token, error in
                if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: error ?? URLError(.userAuthenticationRequired))
                }
            }
        }
    }
    
    // MARK: - CREATE / UPDATE (PUT)
    func setDocument(collection: String, documentId: String, fields: [String: Any]) async throws {
        
        let token = try await getToken()
        let url = URL(string: "\(baseURL)/\(collection)/\(documentId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"   // PATCH = 부분 업데이트, PUT = 전체 덮어쓰기
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "fields": encodeFields(fields)
        ])
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - READ (GET)
    func getDocument(collection: String, documentId: String) async throws -> [String: Any] {
        let token = try await getToken()
        let url = URL(string: "\(baseURL)/\(collection)/\(documentId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        // Firestore 응답 필드 디코딩
        return decodeFields(json["fields"] as? [String: Any] ?? [:])
    }
    
    // MARK: - DELETE
    func deleteDocument(collection: String, documentId: String) async throws {
        let token = try await getToken()
        let url = URL(string: "\(baseURL)/\(collection)/\(documentId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Firestore 타입 인코딩
    // Firestore REST는 {"stringValue": "..."} 형태로 타입을 명시해야 함
    private func encodeFields(_ fields: [String: Any]) -> [String: Any] {
        var encoded: [String: Any] = [:]
        for (key, value) in fields {
            switch value {
            case let v as String:
                encoded[key] = ["stringValue": v]
            case let v as Int:
                encoded[key] = ["integerValue": v]
            case let v as Double:
                encoded[key] = ["doubleValue": v]
            case let v as Bool:
                encoded[key] = ["booleanValue": v]
            case let v as [String]:
                encoded[key] = ["arrayValue": ["values": v.map { ["stringValue": $0] }]]
            default:
                encoded[key] = ["stringValue": "\(value)"]
            }
        }
        return encoded
    }
    
    // MARK: - Firestore 타입 디코딩
    private func decodeFields(_ fields: [String: Any]) -> [String: Any] {
        var decoded: [String: Any] = [:]
        for (key, value) in fields {
            guard let typeMap = value as? [String: Any] else { continue }
            decoded[key] = typeMap["stringValue"]
                ?? typeMap["integerValue"]
                ?? typeMap["doubleValue"]
                ?? typeMap["booleanValue"]
                ?? typeMap["arrayValue"]
        }
        return decoded
    }
}
