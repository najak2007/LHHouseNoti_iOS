//
//  AlarmSettingView.swift
//  LHHouseNoti
//
//  Created by najak on 6/26/26.
//

import SwiftUI

struct AlarmSettingView: View {
    @ObservedObject var viewModel: JSWebViewModel
    @StateObject private var remoteConfig = RemoteConfigManager()
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("알림 설정")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.leading, 20)
                    Spacer()
                }
                .frame(height: 45)
                
                List {
#if true
                    Section(header: SectionHeaderView(title: "지역 설정")) {
                        let locations = remoteConfig.locationNames
                        ForEach(stride(from: 0, to: locations.count, by: 2).map { $0 }, id: \.self) { index in
                            HStack(spacing: 8) {
                                ListRowView(viewModel: viewModel, fieldKey: "CNP_CD_NM", label: "\(locations[index])") { isOn, fieldItem in
                                    Task {
                                        try await viewModel.setUsersNotices(isOn, "CNP_CD_NM", fieldItem)
                                    }
                                }
                                    .frame(maxWidth: .infinity)
                                
                                if index + 1 < locations.count {
                                    ListRowView(viewModel: viewModel, fieldKey: "CNP_CD_NM", label: "\(locations[index + 1])") { isOn, fieldItem in
                                        Task {
                                            try await viewModel.setUsersNotices(isOn, "CNP_CD_NM", fieldItem)
                                        }
                                    }
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 18)
                            .listRowSeparatorTint(Color.gray.opacity(0.3))
                        }
                    }
                    .listSectionSeparator(.hidden)
                    .listRowBackground(Color.white)   // ← 흰색으로 변경
#else
                    Section(header: SectionHeaderView(title: "지역 설정")) {
                        let pairs = LocationName.allCases.chunked(by: 2)  // Swift 5.9+
                        ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                            HStack(spacing: 8) {
                                ForEach(pair, id: \.self) { location in
                                    ListRowView(label: "\(location)", isOn: false) { _ in }
                                        .frame(maxWidth: .infinity)
                                }
                                if pair.count == 1 { Spacer().frame(maxWidth: .infinity) }
                            }
                            .listRowSeparatorTint(Color.gray.opacity(0.3))
                        }
                    }
                    .listSectionSeparator(.hidden)
                    .listRowBackground(Color.white)   // ← 흰색으로 변경
#endif

                    Section(header: SectionHeaderView(title: "공고 상태 설정")) {
                        let panSSNames = remoteConfig.panSSNames
                        ForEach(stride(from: 0, to: panSSNames.count, by: 2).map { $0 }, id: \.self) { index in
                            HStack(spacing: 8) {
                                ListRowView(viewModel: viewModel, fieldKey: "PAN_SS", label: "\(panSSNames[index])", onColor: Color(red: 0.13, green: 0.59, blue: 0.33)) { isOn, fieldItem in
                                    Task {
                                        try await viewModel.setUsersNotices(isOn, "PAN_SS", fieldItem)
                                    }
                                }
                                    .frame(maxWidth: .infinity)
                                if index + 1 < panSSNames.count {
                                    ListRowView(viewModel: viewModel, fieldKey: "PAN_SS", label: "\(panSSNames[index + 1])", onColor: Color(red: 0.13, green: 0.59, blue: 0.33)) { isOn, fieldItem in
                                        Task {
                                            try await viewModel.setUsersNotices(isOn, "PAN_SS", fieldItem)
                                        }
                                    }
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 18)
                            .listRowSeparatorTint(Color.gray.opacity(0.3))
                        }
                    }
                    .listSectionSeparator(.hidden)
                    .listRowBackground(Color.white)

                    Section(header: SectionHeaderView(title: "공고 유형")) {
                        let uppaistpcdNames = remoteConfig.uppaistpcdNames
                        
                        ForEach(stride(from: 0, to: uppaistpcdNames.count, by: 2).map { $0 }, id: \.self) { index in
                            HStack(spacing: 8) {
                                ListRowView(viewModel: viewModel, fieldKey: "UPP_AIS_TP_CD", label: "\(uppaistpcdNames[index])", onColor: .black) { isOn, fieldItem in
                                    Task {
                                        try await viewModel.setUsersNotices(isOn, "UPP_AIS_TP_CD", fieldItem)
                                    }
                                }
                                    .frame(maxWidth: .infinity)
                                if index + 1 < uppaistpcdNames.count {
                                    ListRowView(viewModel: viewModel, fieldKey: "UPP_AIS_TP_CD", label: "\(uppaistpcdNames[index + 1])", onColor: .black) { isOn, fieldItem in
                                        Task {
                                            try await viewModel.setUsersNotices(isOn, "UPP_AIS_TP_CD", fieldItem)
                                        }
                                    }
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 18)
                            .listRowSeparatorTint(Color.gray.opacity(0.3))
                        }
                    }
                    .listSectionSeparator(.hidden)
                    .listRowBackground(Color.white)
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)     // ← 필수
                .background(Color.white)

            }
        }
    }
}
