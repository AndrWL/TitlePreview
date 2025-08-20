//
//  QuizRepository.swift
//  TitlePreview
//
//  Created by ANDRII LEBEDIEV on 19.08.2025.
//

import Foundation

public protocol QuizRepository {
    func fetchQuiz() async throws -> Quiz
  func saveProgress(index: Int, answers: [String: [String]]) throws
  func loadProgress() throws -> (index: Int, answers: [String: [String]])?
  func clearProgress() throws
}

public final class QuizRepositoryImpl: QuizRepository {
    private let remote: QuizRemoteDataSource
    private let local: QuizLocalDataSource
    private let persistence: QuizPersistence
    private var cachedQuiz: Quiz?
    
    public init(
        remote: QuizRemoteDataSource,
        local: QuizLocalDataSource,
        persistence: QuizPersistence
    ) {
        self.remote = remote
        self.local = local
        self.persistence = persistence
    }
    
    public func fetchQuiz() async throws -> Quiz {
        let data: Data
        
        do {
            data = try await remote.fetch()
        } catch {
            data = try local.load()
        }
        
        let quiz = try JSONDecoder().decode(Quiz.self, from: data)
        cachedQuiz = quiz
        
        return quiz
    }
    
    public func saveProgress(index: Int, answers: [String:[String]]) throws {
        try persistence.save(index: index, answers: answers)
    }
    
    public func loadProgress() throws -> (index: Int, answers: [String:[String]])? {
        try persistence.load()
    }
    
    public func clearProgress() throws {
        try persistence.clear()
    }
}
