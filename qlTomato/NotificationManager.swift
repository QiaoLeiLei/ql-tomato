import Foundation
import UserNotifications
import AppKit
import Combine

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            guard let self = self else { return }
            Task { @MainActor in
                if granted {
                    print("通知权限已获取")
                } else {
                    print("通知权限被拒绝")
                }
                
                if let error = error {
                    print("请求通知权限时出错: \(error.localizedDescription)")
                }
                
                self.checkAuthorizationStatus()
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func showPhaseCompleteNotification(phase: TomatoPhase, session: Int) {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        
        switch phase {
        case .focus:
            content.title = "专注时间结束！"
            content.body = "第 \(session) 组专注完成，是时候休息一下了"
            content.sound = .default
            
        case .shortBreak:
            content.title = "短休息结束！"
            content.body = "休息充分，准备开始下一组专注"
            content.sound = .default
            
        case .longBreak:
            content.title = "长休息结束！"
            content.body = "休息充分，准备开始新的工作周期"
            content.sound = .default
        }
        
        // 添加交互按钮
        if phase != .focus {
            // 如果是休息结束，提供开始专注的快捷按钮
            let startAction = UNNotificationAction(
                identifier: "START_FOCUS",
                title: "开始专注",
                options: [.foreground]
            )
            let category = UNNotificationCategory(
                identifier: "BREAK_END",
                actions: [startAction],
                intentIdentifiers: [],
                options: []
            )
            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = "BREAK_END"
        }
        
        let request = UNNotificationRequest(
            identifier: "tomato-phase-\(phase.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // 立即发送
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知发送失败: \(error.localizedDescription)")
            }
        }
    }
    
    func playNotificationSound() {
        // 播放系统提示音
        NSSound.beep()
        
        // 连续播放3次提示音，间隔0.5秒
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            NSSound.beep()
            
            try? await Task.sleep(for: .milliseconds(500))
            NSSound.beep()
        }
        
        // 也可以尝试播放自定义声音文件
        // if let path = Bundle.main.path(forResource: "notification", ofType: "wav") {
        //     let sound = NSSound(contentsOfFile: path, byReference: false)
        //     sound?.play()
        // }
    }
}
