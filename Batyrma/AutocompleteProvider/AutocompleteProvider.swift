//
//  AutocompleteProvider.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import Foundation

protocol AutocompleteProvider: AnyObject {
    func suggestions(for text: String) -> [Suggestion]
}
