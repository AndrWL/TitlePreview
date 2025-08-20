//
//  QuizFlowFeature.swift
//  TitlePreview
//
//  Created by ANDRII LEBEDIEV on 19.08.2025.
//

import SwiftUI
import ComposableArchitecture

// MARK: - QuizFlowFeature

struct QuizFlowFeature: Reducer {
    struct State: Equatable {
        var quiz: Quiz
        var index: Int = 0
        var answers: [String: Set<String>] = [:]
        
        var current: Question { quiz.questions[index] }
        var isLast: Bool { index >= quiz.questions.count - 1 }
        var canGoBack: Bool { index > 0 }
        
        var isCurrentValid: Bool {
            let selected = answers[current.id] ?? []
            return !selected.isEmpty
        }
    }
    
    enum Action: Equatable {
        case optionTapped(String)
        case continueTapped
        case backTapped
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case finished([String: [String]])
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .optionTapped(let optionId):
                let qid = state.current.id
                var set = state.answers[qid] ?? []
                
                if set.contains(optionId) {
                    set.remove(optionId)
                } else {
                    set.insert(optionId)
                }
                
                state.answers[qid] = set
                return .none
            case .continueTapped:
                guard state.isCurrentValid else { return .none }
                if state.isLast {
                    let payload = state.answers.mapValues(Array.init)
                    return .send(.delegate(.finished(payload)))
                }
                state.index += 1
                return .none
            case .backTapped:
                guard state.canGoBack else { return .none }
                state.index -= 1
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - View

struct QuizFlowView: View {
    let store: StoreOf<QuizFlowFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            VStack(spacing: 0) {
                HStack {
                    if vs.canGoBack {
                        Button {
                            vs.send(.backTapped, animation: .easeInOut(duration: 0.28))
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    
                    Spacer()
                    
                    Text(vs.current.navTitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black)
                    Spacer()
                    
                    if vs.canGoBack {
                        Color.clear.frame(width: 22, height: 22)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                ZStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(vs.current.title)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 6)
                            
                            if let subtitle = vs.current.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 6)
                            }
                            
                            questionContent(
                                question: vs.current,
                                selected: vs.answers[vs.current.id] ?? [],
                                onTap: { vs.send(.optionTapped($0)) }
                            )
                            .padding(.horizontal, 16)
                            
                            Spacer(minLength: 120)
                        }
                    }
                    .id(vs.current.id)
                    .contentTransition(.opacity)
                }
                .clipped()
                .animation(.easeInOut(duration: 0.28), value: vs.index)
                
                VStack(spacing: 0) {
                    Button { vs.send(.continueTapped, animation: .easeInOut(duration: 0.28)) } label: {
                        Text("CONTINUE")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(vs.isCurrentValid ? Color.black : Color.black.opacity(0.25))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .disabled(!vs.isCurrentValid)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
    }
    
    @ViewBuilder
    private func questionContent(
        question: Question,
        selected: Set<String>,
        onTap: @escaping (String) -> Void
    ) -> some View {
        switch question.type {
        case .checkbox:
            VStack(spacing: 14) {
                ForEach(question.options, id: \.id) { opt in
                    if case let .text(id, title, subtitle) = opt {
                        CheckboxCard(
                            title: title,
                            subtitle: subtitle,
                            isOn: selected.contains(id)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(id) }
                    }
                }
            }
        case .grid:
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12),
                          GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(question.options, id: \.id) { opt in
                    if case let .image(id, title, asset) = opt {
                        ImageCard(
                            title: title,
                            asset: asset,
                            isSelected: selected.contains(id)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(id) }
                    }
                }
            }
            
        case .color:
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 12
            ) {
                ForEach(question.options, id: \.id) { opt in
                    if case let .color(id, title, hex) = opt {
                        ColorSwatch(
                            title: title ?? "",
                            hex: hex,
                            isSelected: selected.contains(id)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(id) }
                    }
                }
            }
        }
    }
}

private struct ImageCard: View {
    let title: String
    let asset: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .overlay(
                        ZStack {
                            Color.gray.opacity(0.06)
                            Image(asset)
                                .resizable()
                                .scaledToFit()
                                .padding(10)
                        }
                    )
                    .frame(height: 130)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.black : Color.gray.opacity(0.3),
                                    lineWidth: isSelected ? 2 : 1)
                    )
                
                CheckmarkBox(isOn: isSelected, showsEmptyWhenOff: true)
                    .padding(6)
            }
            
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

private struct CheckboxCard: View {
    let title: String
    let subtitle: String?
    let isOn: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            CheckmarkBox(isOn: isOn, showsEmptyWhenOff: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isOn ? Color.black : Color.gray.opacity(0.35),
                        lineWidth: isOn ? 2 : 1)
                .background(RoundedRectangle(cornerRadius: 6).fill(.white))
        )
        .animation(.easeInOut(duration: 0.18), value: isOn)
    }
}

private struct ColorSwatch: View {
    let title: String
    let hex: String
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? .black : Color.gray.opacity(0.3),
                                lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 6) {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex))
                            .frame(width: 32, height: 32)
                        
                        Text(title)
                            .font(.system(size: 13, weight: isSelected ? .bold : .thin))
                            .foregroundStyle(.black)
                        Spacer()
                    }
                        .padding(.vertical, 8)
                )
                .frame(height: 108)
            
            CheckmarkBox(isOn: isSelected, showsEmptyWhenOff: false)
                .padding(6)
        }
        .contentShape(Rectangle())
    }
}
