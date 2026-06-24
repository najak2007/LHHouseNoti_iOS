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
        
        // 1. 익명 로그인 (타임아웃 10초)
        if Auth.auth().currentUser == nil {
            print("🔐 익명 로그인 시도...")
            
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await Auth.auth().signInAnonymously()
                    print("✅ 익명 로그인 성공")
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: 10_000_000_000) // 10초
                    print("❌ 익명 로그인 타임아웃")
                    throw URLError(.timedOut)
                }
                // 먼저 끝나는 태스크 결과 사용
                try await group.next()
                group.cancelAll()
            }
        }
        
        // 2. 토큰 획득
        guard let user = Auth.auth().currentUser else {
            throw URLError(.userAuthenticationRequired)
        }
        
        print("🎫 토큰 획득 시도...")
        let token = try await user.getIDToken()
        print("✅ 토큰 획득 성공")
        return token
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
