//
//  Constants.swift
//  FreshBooks
//
//  Created by Dion Durigon on 2020-12-02.
//  Copyright © 2020 FreshBooks. All rights reserved.
//

import UIKit

struct Constants {
    static let defaultContentFont   = UIFont.systemFont(ofSize: 14)
    static let defaultHtmlFont      = UIFont.systemFont(ofSize: 24)
    static let defaultMissingImage  = UIView.tintedMissingImage
    static let formatBarIconSize    = CGSize(width: 20.0, height: 20.0)
    static let headers              = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
    static let lists                = [TextList.Style.unordered, .ordered]
    static let moreAttachmentText   = "more"
    static let titleInsets          = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    static var mediaMessageAttributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                                                        .paragraphStyle: paragraphStyle,
                                                        .foregroundColor: UIColor.white]
        return attributes
    }
}

