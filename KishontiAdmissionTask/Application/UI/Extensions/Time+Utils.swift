//
//  Time+Utils.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 23..
//

import Foundation

extension TimeInterval {
    static func hours(_ n: Int) -> TimeInterval {
        Double(n) * 3600
    }
    
    static func minutes(_ n: Int) -> TimeInterval {
        Double(n) * 60
    }
    
    static func seconds(_ n: Int) -> TimeInterval {
        Double(n)
    }
}
