//
//  GitHubRelease.swift
//  GLM Usage
//
//  GitHub Release API 响应模型
//

import Foundation

struct GitHubRelease: Codable {
    let tagName: String
    let name: String?
    let body: String?
    let htmlUrl: String
    let assets: [Asset]
    let draft: Bool
    let prerelease: Bool

    struct Asset: Codable {
        let name: String
        let browserDownloadUrl: String
        let size: Int?

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
            case size
        }
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case assets
        case draft
        case prerelease
    }
}
