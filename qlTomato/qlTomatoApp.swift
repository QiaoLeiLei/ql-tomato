//
//  qlTomatoApp.swift
//  qlTomato
//
//  Created by 乔磊磊 on 2025/12/23.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct qlTomatoApp: App {
    @StateObject private var timer = TomatoTimer()
    

    
    var body: some Scene {
        // 菜单栏组件
        TomatoMenuBar(timer: timer)
    }
}


