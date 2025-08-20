//
//  AppFeature.swift
//  TitlePreview
//
//  Created by ANDRII LEBEDIEV on 19.08.2025.
//

import ComposableArchitecture
import SwiftUI

struct AppFeature: Reducer {
    struct State: Equatable {
        var intro = IntroFeature.State()
        var quizFlow: QuizFlowFeature.State?
    }

    enum Action {
        case intro(IntroFeature.Action)
        case quizFlow(QuizFlowFeature.Action)
    }
    
    @Dependency(\.quizClient) var quizClient

    var body: some ReducerOf<Self> {
        Scope(state: \.intro, action: /Action.intro) {
            IntroFeature()
        }
        .ifLet(\.quizFlow, action: /Action.quizFlow) {
            QuizFlowFeature()
        }

        Reduce { state, action in
            switch action {
            case .intro(.loadCompleted(.success(let quiz))):
                state.quizFlow = QuizFlowFeature.State(quiz: quiz)
                return .none

            case .quizFlow(.delegate(.finished)):
                try? quizClient.clear()
                state.quizFlow = nil
                return .none

            default:
                return .none
            }
        }
    }
}

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            IfLetStore(
                store.scope(state: \.quizFlow, action: AppFeature.Action.quizFlow)
            ) { quizStore in
                QuizFlowView(store: quizStore)
            } else: {
                IntroFeatureView(
                    store: store.scope(state: \.intro, action: AppFeature.Action.intro)
                )
            }
        }
    }
}
