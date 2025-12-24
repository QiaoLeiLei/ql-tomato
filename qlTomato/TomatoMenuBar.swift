import SwiftUI
import UserNotifications

struct TomatoMenuBar: Scene {
    @ObservedObject var timer: TomatoTimer
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(timer: timer)
                .onAppear {
                    // 延迟请求通知权限，确保应用完全启动
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationManager.shared.requestAuthorization()
                    }
                }
        } label: {
            Text(timer.menuBarTitle)
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject var timer: TomatoTimer
    @State private var showingNotificationAlert = false
    
    private var isRunning: Bool {
        switch timer.state {
        case .running:
            return true
        case .idle, .paused:
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 状态显示区域
            VStack(spacing: 8) {
                Text(timer.statusText)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(timer.formattedTime)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(isRunning ? .green : .orange)
                
                if timer.currentSession > 0 {
                    Text("第 \(timer.currentSession) 组 - 完成 \(timer.completedSessions) 组")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            // 控制按钮区域
            VStack(spacing: 4) {
                switch timer.state {
                case .idle:
                    Button(action: { timer.start() }) {
                        Label("开始专注", systemImage: "play.circle.fill")
                    }
                    .keyboardShortcut("s", modifiers: .command)
                    
                case .running:
                    Button(action: { timer.pause() }) {
                        Label("暂停", systemImage: "pause.circle.fill")
                    }
                    .keyboardShortcut("p", modifiers: .command)
                    
                    Button(action: { timer.skip() }) {
                        Label("跳过", systemImage: "forward.circle.fill")
                    }
                    .keyboardShortcut("f", modifiers: .command)
                    
                case .paused:
                    Button(action: { timer.resume() }) {
                        Label("继续", systemImage: "play.circle.fill")
                    }
                    .keyboardShortcut("r", modifiers: .command)
                    
                    Button(action: { timer.stop() }) {
                        Label("停止", systemImage: "stop.circle.fill")
                    }
                    .keyboardShortcut("t", modifiers: .command)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            
            Divider()
            
            // 配置信息
            VStack(alignment: .leading, spacing: 6) {
                Text("配置信息")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.orange)
                
                Text("专注时间: \(timer.configFocusTime)")
                    .font(.body)
                    .foregroundColor(Color.blue)
                
                Text("短休息: \(timer.configShortBreakTime)")
                    .font(.body)
                    .foregroundColor(Color.blue)
                
                Text("长休息: \(timer.configLongBreakTime) (每\(timer.configSessionsPerLongBreak)组)")
                    .font(.body)
                    .foregroundColor(Color.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Divider()
            
            // 关于和退出
            VStack(spacing: 4) {
                Button("关于番茄钟") {
                     NSWorkspace.shared.open(URL(string: "https://github.com/")!)
                 }
                 
                Divider()
                
                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .onReceive(NotificationCenter.default.publisher(for: .tomatoPhaseCompleted)) { notification in
            handlePhaseCompletion(notification)
        }
    }
    
    private func handlePhaseCompletion(_ notification: Notification) {
        guard let phase = notification.userInfo?["phase"] as? TomatoPhase else { return }
        let session = notification.userInfo?["session"] as? Int ?? 1
        
        // 使用 NotificationManager 显示系统通知
        NotificationManager.shared.showPhaseCompleteNotification(phase: phase, session: session)
        
        // 播放提示音
        NotificationManager.shared.playNotificationSound()
    }
}
