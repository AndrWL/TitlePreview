//
//  Quiz.swift
//  TitlePreview
//
//  Created by ANDRII LEBEDIEV on 19.08.2025.
//

import Foundation

public struct Quiz: Codable, Equatable {
    public let version: Int
    public let title: String?
    public let questions: [Question]
}

public struct Question: Codable, Equatable, Identifiable {
    public enum QType: String, Codable {
        case checkbox, grid, color
    }

    public let id: String
    public let type: QType
    public let navTitle: String
    public let title: String
    public let subtitle: String?
    public let min: Int?
    public let max: Int?
    public let options: [Option]
}

public enum Option: Equatable, Identifiable, Codable {
    case text(id: String, title: String, subtitle: String?)
    case image(id: String, title: String, asset: String)
    case color(id: String, title: String?, hex: String)

    public var id: String {
          switch self {
          case let .text(id, _, _):   return id
          case let .image(id, _, _):  return id
          case let .color(id, _, _):  return id
          }
      }

      public var title: String? {
          switch self {
          case let .text(_, title, _):   return title
          case let .image(_, title, _):  return title
          case let .color(_, title, _):  return title
          }
      }

      public var subtitle: String? {
          if case let .text(_, _, subtitle) = self { return subtitle }
          return nil
      }

      public var asset: String? {
          if case let .image(_, _, asset) = self { return asset }
          return nil
      }

      public var color: String? {
          if case let .color(_, _, color) = self { return color }
          return nil
      }

    private enum CodingKeys: String, CodingKey {
        case type, id, title, subtitle, image, hex
    }
    
    private enum Kind: String, Codable {
        case text, image, color
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .type) {
        case .text:
            self = .text(
                id: try c.decode(String.self, forKey: .id),
                title: try c.decode(String.self, forKey: .title),
                subtitle: try c.decodeIfPresent(String.self, forKey: .subtitle)
            )
        case .image:
            self = .image(
                id: try c.decode(String.self, forKey: .id),
                title: try c.decode(String.self, forKey: .title),
                asset: try c.decode(String.self, forKey: .image)
            )
        case .color:
            self = .color(
                id: try c.decode(String.self, forKey: .id),
                title: try c.decodeIfPresent(String.self, forKey: .title),
                hex: try c.decode(String.self, forKey: .hex)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .text(id, title, subtitle):
            try container.encode(Kind.text, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(title, forKey: .title)
            try container.encodeIfPresent(subtitle, forKey: .subtitle)
        case let .image(id, title, asset):
            try container.encode(Kind.image, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(title, forKey: .title)
            try container.encode(asset, forKey: .image)
        case let .color(id, title, hex):
            try container.encode(Kind.color, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(title, forKey: .title)
            try container.encode(hex, forKey: .hex)
        }
    }
}

public enum QuizError: Error {
    case notFound, invalidPayload, storage, network, unknown
}
