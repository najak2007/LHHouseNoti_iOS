//
//  CustomToggleStyle.swift
//  LHHouseNoti
//
//  Created by najak on 6/26/26.
//

import SwiftUI

struct CustomToggleStyle: ToggleStyle {
    let onColor: Color
    let offColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(configuration.isOn ? onColor : offColor)
            .frame(width: 44, height: 26)
            .overlay(
                Circle()
                    .fill(.white)
                    .padding(3)
                    .offset(x: configuration.isOn ? 9 : -9)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    configuration.isOn.toggle()
                }
            }
    }
}
