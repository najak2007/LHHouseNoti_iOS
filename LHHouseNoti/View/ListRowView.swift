//
//  ListRowView.swift
//  LHHouseNoti
//
//  Created by najak on 6/26/26.
//

import SwiftUI

struct ListRowView: View {
    @ObservedObject var viewModel: JSWebViewModel
    let fieldKey: String
    let label: String
    var onColor: Color = Color(red: 0.10, green: 0.35, blue: 0.80)
    var offColor: Color = Color(red: 0.80, green: 0.82, blue: 0.86)
    @State private var isTurnedOn: Bool = false
    @State private var isAppearTurnedOn: Bool = false

    var onSelectHandler: ((Bool, String) -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .center) {
            Text(label.getKey)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(red: 0.20, green: 0.20, blue: 0.20))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Toggle("", isOn: $isTurnedOn)
                .labelsHidden()
                .toggleStyle(CustomToggleStyle(
                    onColor: onColor,
                    offColor: offColor   // ← 회색 테두리 느낌
                ))
                .scaleEffect(0.8)
                .frame(width: 44)
                .onChange(of: isTurnedOn) { oldValue, newValue in
                    onSelectHandler?(newValue, label)
                }
        }
        .padding(10)
        .onReceive(lhhouseAlarmYNHandler) { receiveInfo in
            if let fieldItem = receiveInfo["fieldKey"] as? String,
               let isON = receiveInfo["isON"] as? Bool {
                if fieldItem == label.getKey {
                    isTurnedOn = isON
                }
            }
        }
        .onAppear {
            guard let editFielsList: [String] = viewModel.usersAlarmiInfo[fieldKey] as? [String]
            else {
                return
            }
            if let _ = editFielsList.firstIndex(where: { $0 == label.getKey }) {
                isTurnedOn = true
            } else {
                isTurnedOn = false
            }
        }
    }
}
