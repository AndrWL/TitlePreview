//
//  IntroFeature.swift
//  TitlePreview
//
//  Created by ANDRII LEBEDIEV on 19.08.2025.
//

import ComposableArchitecture
import SwiftUI

struct IntroFeature: Reducer {
    struct State: Equatable {
        var title: String = "Online Personal \nStyling.\nOutfits for Every Woman."
        var isLoadingButton: Bool = false
        var quiz: Quiz? = nil
        var lastError: String? = nil
    }
    
    enum Action: Equatable {
        case takeQuizButtonTapped
        case loadCompleted(TaskResult<Quiz>)
    }
    
    private enum CancelID {
        case load
    }
    
    @Dependency(\.quizClient) var quizClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .takeQuizButtonTapped:
                state.isLoadingButton = true
                state.lastError = nil
                
                return .run { send in
                    do {
                        let quiz = try await quizClient.fetch()
                        await send(.loadCompleted(.success(quiz)))
                    } catch {
                        await send(.loadCompleted(.failure(error)))
                    }
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)
            case .loadCompleted(let result):
                state.isLoadingButton = false
                switch result {
                case .success(let quiz):
                    state.quiz = quiz
                    return .none
                case .failure(let error):
                    state.lastError = error.localizedDescription
                    return .none
                }
            }
        }
    }
}

struct IntroFeatureView: View {
    let store: StoreOf<IntroFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            // use GeometryReader to get the actual SafeAreaInset.
            // This allows the content to be automatically raised above the home indicator / bottom bar
            // on different iPhone and iPad models. Without this indentation, it would have to be set "manually".
            GeometryReader { geo in
                ZStack {
                    Image(ImageResource.Intro.intro)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .ignoresSafeArea()

                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black.opacity(0.0), location: 0.0),
                            .init(color: .black.opacity(0.3), location: 0.5),
                            .init(color: .black.opacity(0.6), location: 0.6),
                            .init(color: .black.opacity(1.0), location: 0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    VStack(alignment: .leading, spacing: 61) {
                        Spacer()

                        Text(viewStore.title)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        Button {
                            viewStore.send(.takeQuizButtonTapped)
                        } label: {
                            Group {
                                if viewStore.isLoadingButton {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.secondary)
                                } else {
                                    Text("TAKE A QUIZ")
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                }
                            }
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 48,
                                alignment: .center
                            )
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.bottom, geo.safeAreaInsets.bottom)
                }
            }
        }
    }
}

#Preview {
    IntroFeatureView(store: Store(
        initialState: IntroFeature.State()) {
            IntroFeature()
        }
    )
}
