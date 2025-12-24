import Foundation
import Combine

enum TomatoPhase: String, CaseIterable {
    case focus = "专注"
    case shortBreak = "短休息"
    case longBreak = "长休息"
}

enum TomatoState {
    case idle
    case running(phase: TomatoPhase)
    case paused(phase: TomatoPhase)
}

struct TomatoConfig {
    let focusTime: TimeInterval // 专注时间（秒）
    let shortBreakTime: TimeInterval // 短休息时间（秒）
    let longBreakTime: TimeInterval // 长休息时间（秒）
    let sessionsPerLongBreak: Int // 多少组后长休息
    
    nonisolated static let `default` = TomatoConfig(
        focusTime: 25 * 60, // 25分钟
        shortBreakTime: 5 * 60, // 5分钟
        longBreakTime: 15 * 60, // 15分钟
        sessionsPerLongBreak: 4 // 4组后长休息
    )
}

@MainActor // 保证在主线程中运行
class TomatoTimer: ObservableObject {
    @Published var state: TomatoState = .idle
    @Published var remainingTime: TimeInterval = 0
    @Published var currentSession: Int = 0
    @Published var completedSessions: Int = 0
    
    private var timer: Timer?
    private let config: TomatoConfig
    
    init(config: TomatoConfig = .default) {
        self.config = config
    }
    
    func start() {
        guard case .idle = state else { return }
        
        currentSession = 1
        startPhase(.focus)
        
        // 启动后台任务
        BackgroundManager.shared.startBackgroundTask()
    }
    
    func pause() {
        guard case .running(let phase) = state else { return }
        
        state = .paused(phase: phase)
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        guard case .paused(let phase) = state else { return }
        
        state = .running(phase: phase)
        startTimer()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        remainingTime = 0
        currentSession = 0
        
        // 停止后台任务
        BackgroundManager.shared.stopBackgroundTask()
    }
    
    func skip() {
        timer?.invalidate()
        timer = nil
        
        switch state {
        case .running(let phase), .paused(let phase):
            moveToNextPhase(from: phase)
        case .idle:
            break
        }
    }
    
    private func startPhase(_ phase: TomatoPhase) {
        switch phase {
        case .focus:
            remainingTime = config.focusTime
        case .shortBreak:
            remainingTime = config.shortBreakTime
        case .longBreak:
            remainingTime = config.longBreakTime
        }
        
        state = .running(phase: phase)
        startTimer()
    }
    
    private func startTimer() {
        // 使用RunLoop.common modes确保计时器在UI操作时也能运行
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
        
        // 将计时器添加到common modes，确保在菜单打开等UI操作时也能运行
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func tick() {
        guard case .running = state else { return }
        
        remainingTime -= 1
        
        if remainingTime <= 0 {
            timer?.invalidate()
            timer = nil
            
            if case .running(let phase) = state {
                handlePhaseComplete(phase)
            }
        }
    }
    
    private func handlePhaseComplete(_ phase: TomatoPhase) {
        // 发送通知
        NotificationCenter.default.post(
            name: .tomatoPhaseCompleted,
            object: nil,
            userInfo: ["phase": phase, "session": currentSession]
        )
        
        moveToNextPhase(from: phase)
    }
    
    private func moveToNextPhase(from currentPhase: TomatoPhase) {
        switch currentPhase {
        case .focus:
            // 专注完成，进入休息
            completedSessions += 1
            
            if currentSession % config.sessionsPerLongBreak == 0 {
                startPhase(.longBreak)
            } else {
                startPhase(.shortBreak)
            }
            
        case .shortBreak, .longBreak:
            // 休息完成，开始下一组专注
            currentSession += 1
            startPhase(.focus)
        }
    }
    
    var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var statusText: String {
        switch state {
        case .idle:
            return "准备就绪"
        case .running(let phase):
            return "\(phase.rawValue) - 运行中"
        case .paused(let phase):
            return "\(phase.rawValue) - 已暂停"
        }
    }
    
    var menuBarTitle: String {
        switch state {
        case .idle:
            return "🍅 准备就绪"
        case .running(let phase):
            let phaseText = phase == .focus ? "专注" : "休息"
            return "\(formattedTime) \(phaseText)"
        case .paused(let phase):
            let phaseText = phase == .focus ? "专注(暂停)" : "休息(暂停)"
            return "\(formattedTime) \(phaseText)"
        }
    }
    
    var configFocusTime: String {
        return "\(Int(config.focusTime / 60))分钟"
    }
    
    var configShortBreakTime: String {
        return "\(Int(config.shortBreakTime / 60))分钟"
    }
    
    var configLongBreakTime: String {
        return "\(Int(config.longBreakTime / 60))分钟"
    }
    
    var configSessionsPerLongBreak: String {
        return "\(config.sessionsPerLongBreak)"
    }
}

extension Notification.Name {
    static let tomatoPhaseCompleted = Notification.Name("tomatoPhaseCompleted")
}
