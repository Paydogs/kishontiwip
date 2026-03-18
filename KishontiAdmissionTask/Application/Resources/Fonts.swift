//
//  Fonts.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

public struct Fonts {
    static var headline: Font {
        KishontiAdmissionTaskFontFamily.Geist.bold.swiftUIFont(size: 14)
    }
    
    static var subheadline: Font {
        KishontiAdmissionTaskFontFamily.Geist.light.swiftUIFont(size: 12)
    }
    
    static var footnote: Font {
        KishontiAdmissionTaskFontFamily.Geist.light.swiftUIFont(size: 10)
    }
    
    static func regular(size: CGFloat) -> Font {
        KishontiAdmissionTaskFontFamily.Geist.regular.swiftUIFont(size: size)
    }
    
    static func bold(size: CGFloat) -> Font {
        KishontiAdmissionTaskFontFamily.Geist.bold.swiftUIFont(size: size)
    }
    
    static func typewriter(size: CGFloat) -> Font {
        KishontiAdmissionTaskFontFamily.LibreBaskerville.regular.swiftUIFont(size: size)
    }
}
