import Foundation
import AppKit
import UserNotifications

class BackgroundManager {
    static let shared = BackgroundManager()
    
    private var activity: NSObjectProtocol?
    private let timer = Timer()
    
    private init() {}
    
    func startBackgroundTask() {
        // 防止应用进入休眠状态
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.idleSystemSleepDisabled, .suddenTerminationDisabled],
            reason: "番茄时钟运行中"
        )
        
        // 设置应用为前台应用（可选）
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func stopBackgroundTask() {
        if let activity = activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知权限已获取")
            } else {
                print("通知权限被拒绝")
            }
            
            if let error = error {
                print("请求通知权限时出错: \(error.localizedDescription)")
            }
        }
    }
}