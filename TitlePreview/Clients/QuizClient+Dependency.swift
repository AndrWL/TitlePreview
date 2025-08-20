//
//  QuizClient+Dependency.swift
//  TitlePreview
//
//  Created by ANDRII LEBEDIEV on 19.08.2025.
//

import Dependencies
import Foundation

struct QuizClient {
    var fetch: @Sendable () async throws -> Quiz
    var save:  @Sendable (_ idx: Int, _ answers: [String: [String]]) throws -> Void
    var load:  @Sendable () throws -> (Int, [String: [String]])?
    var clear: @Sendable () throws -> Void
}

extension QuizClient {
    static func live() -> Self {
        let repo = QuizRepositoryImpl(
            remote: RCRemoteDataSource(),
            local: BundleLocalDataSource(),
            persistence: UDQuizPersistence()
        )
        
        return QuizClient(
            fetch: { try await repo.fetchQuiz() },
            save: { try repo.saveProgress(index: $0, answers: $1) },
            load: { try repo.loadProgress() },
            clear: { try repo.clearProgress() }
        )
    }
}

private enum QuizClientKey: DependencyKey {
    static let liveValue = QuizClient.live()
}

extension DependencyValues {
    var quizClient: QuizClient {
        get { self[QuizClientKey.self] }
        set { self[QuizClientKey.self] = newValue }
    }
}
