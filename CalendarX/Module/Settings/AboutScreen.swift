//
//  AboutScreen.swift
//  CalendarX
//
//  Created by zm on 2023/3/1.
//

import CalendarXLib
import SwiftUI

struct AboutScreen: View {

    @EnvironmentObject
    private var router: Router

    var body: some View {

        let image = Bundle.isReleaseVersion ? Image.release : Image.beta

        VStack {
            TitleView {
                Text(L10n.Settings.about)
            } leftItems: {
                ScacleImageButton(image: .backward) {
                    router.pop()
                }
            } rightItems: {
                ScacleImageButton(image: .feedback) {
                    router.open(AppLink.gitHub)
                }
            }

            Image(nsImage: NSApp.applicationIconImage)

            Text("Âm Lịch")
                .font(.title)
                .bold()

            HStack {
                Text(L10n.Updater.version)
                Text(Bundle.appVersionName)

                image
                    .appForeground(.accentColor)

            }
            .appForeground(.appSecondary)

            Text("Phát triển từ CalendarX · AGPL-3.0")
                .font(.caption)
                .foregroundStyle(.secondary)
            Link("Mã nguồn CalendarX", destination: URL(string: "https://github.com/ZzzM/CalendarX")!)
                .font(.caption)
            Text("Thêm widget: nhấp phải desktop → Sửa tiện ích → Âm Lịch.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            Spacer()
            Text(Bundle.copyright)
                .font(.footnote)
                .appForeground(.appSecondary)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }
}
