//
//  RCRemoteDataSource.swift
//  TitlePreview
//
//  Created by ANDRII LEBEDIEV on 19.08.2025.
//

import FirebaseRemoteConfig
import Foundation

public protocol QuizRemoteDataSource {
    func fetch() async throws -> Data
}

public protocol QuizLocalDataSource  {
    func load() throws -> Data
}

public protocol QuizPersistence {
  func save(index: Int, answers: [String: [String]]) throws
  func load() throws -> (index: Int, answers: [String: [String]])?
  func clear() throws
}

public final class RCRemoteDataSource: QuizRemoteDataSource {
    private let rc: RemoteConfig
    private let quizKey = "quiz_config"
    
    public init(rc: RemoteConfig = .remoteConfig()) {
        self.rc = rc
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        rc.configSettings = settings
    }
    
    public func fetch() async throws -> Data {
        let _ = try await rc.fetchAndActivate()
        let value = rc.configValue(forKey: quizKey).stringValue
        
        guard let data = value.data(using: .utf8) else { throw QuizError.notFound }
        return data
    }
}

public final class UDQuizPersistence: QuizPersistence {
    private let idxKey = "quiz.idx"
    private let ansKey = "quiz.answers"
    
    public func save(index: Int, answers: [String: [String]]) throws {
        UserDefaults.standard.set(index, forKey: idxKey)
        let data = try JSONEncoder().encode(answers)
        UserDefaults.standard.set(data, forKey: ansKey)
    }
    
    public func load() throws -> (index: Int, answers: [String: [String]])? {
        let ud = UserDefaults.standard
        guard let data = ud.data(forKey: ansKey) else { return nil }
        
        let answer = try JSONDecoder().decode([String: [String]].self, from: data)
        
        return (ud.integer(forKey: idxKey), answer)
    }
    
    public func clear() throws {
        UserDefaults.standard.removeObject(forKey: idxKey)
        UserDefaults.standard.removeObject(forKey: ansKey)
    }
}

public final class BundleLocalDataSource: QuizLocalDataSource {
    private let filename: String
    
    public init(filename: String = "quiz_mock") { self.filename = filename }
    
    public func load() throws -> Data {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json")
        else { throw QuizError.notFound }
        
        return try Data(contentsOf: url)
    }
}
