//
//  SegmentedPicker.swift
//  CalendarX
//
//  Created by zm on 2025/3/10.
//

import SwiftUI

struct SegmentedPicker<Item: Hashable,  ItemLabel: View>: View {
    let items: [Item]
    @Binding
    var selection: Item
    let itemLabel: (Item) -> ItemLabel

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(items, id: \.self) { itemLabel($0).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}
