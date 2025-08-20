//
//  CheckmarkBox.swift
//  TitlePreview
//
//  Created by Developer on 20.08.2025.
//

import SwiftUI

public struct CheckmarkBox: View {
    let isOn: Bool
    let showsEmptyWhenOff: Bool
    var size: CGFloat = 22
    var cornerRadius: CGFloat = 3
    
    public var body: some View {
        ZStack {
            if isOn {
                Image(systemName: "checkmark.square.fill")
                    .resizable()
                    .frame(width: size, height: size)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black)
            } else if showsEmptyWhenOff {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.black.opacity(0.35), lineWidth: 1)
                    .frame(width: size, height: size)
            }
        }
        .contentShape(Rectangle())
    }
}
