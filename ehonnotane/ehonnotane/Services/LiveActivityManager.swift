import Foundation
import ActivityKit
import UIKit
import Combine
import SwiftUI

/// 絵本生成のLive Activity（Dynamic Island & ロック画面表示）と
/// バックグラウンドでの処理継続を管理するクラス
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    // 現在実行中のActivityを保持
    private var currentActivity: Activity<GenerationActivityAttributes>?
    
    // バックグラウンドタスクのID
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // 進行状況の擬似タイマー（APIレスポンス以外でも進捗を進めるため）
    private var progressTimer: Timer?
    private var generatedBookTitle: String = ""
    private var estimatedCompletionTime: Date = Date()
    private var storybookId: Int?
    private var pollingTask: Task<Void, Never>?
    private var pushTokenTask: Task<Void, Never>?
    
    // 実際の進捗を取得するためのクロージャー（メインアプリから注入）
    public var progressFetcher: ((Int) async throws -> (progressPercent: Int, currentPage: Int, totalPages: Int, status: String))?
    
    // フォアグラウンド復帰時のポーリング再開用
    private var foregroundObserver: NSObjectProtocol?
    
    private init() {
        // フォアグラウンド復帰時にポーリングを再開
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            print("🔄 LiveActivityManager: フォアグラウンド復帰 - ポーリング再開チェック")
            print("   storybookId=\(String(describing: self.storybookId)), activity=\(self.currentActivity != nil), pollingTask=\(String(describing: self.pollingTask)), cancelled=\(self.pollingTask?.isCancelled ?? true)")
            // storybookIdがあり、Activityがまだ存在する場合はポーリングを再開
            if self.storybookId != nil && self.currentActivity != nil {
                print("🔄 LiveActivityManager: ポーリングを再開します")
                // バックグラウンドタスクを再取得
                self.beginBackgroundTask()
                // 既存のポーリングをキャンセルしてから新しいタスクを開始（サスペンド状態のタスクを確実にリフレッシュ）
                self.pollingTask?.cancel()
                self.pollingTask = nil
                self.startPollingTask()
            }
        }
    }
    
    deinit {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - バックグラウンドタスク管理
    
    /// アプリがバックグラウンドに移行しても処理（API通信等）を一定時間継続できるようにする
    func beginBackgroundTask() {
#if !os(watchOS) && canImport(UIKit)
        // Widget Extension では UIApplication.shared が使えないため、App Extensionではビルド実行しないようにする
        // より正確には、NS_EXTENSION_UNAVAILABLE を回避するための対応
        guard let sharedApplication = UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? UIApplication else {
            return
        }

        if backgroundTaskID != .invalid {
            print("ℹ️ LiveActivityManager: バックグラウンドタスクは既に開始済み (ID: \(backgroundTaskID))")
            return
        }
        
        backgroundTaskID = sharedApplication.beginBackgroundTask(withName: "GenerateBookTask") { [weak self] in
            // システムによってタスクが強制終了される直前に呼ばれる（通常約30秒後）
            // 注意: Live Activityとポーリングタスクは終了させない
            // フォアグラウンド復帰時にポーリングが再開される
            print("⚠️ バックグラウンドタスクの制限時間に達しました")
            print("   pollingTask=\(String(describing: self?.pollingTask)), storybookId=\(String(describing: self?.storybookId))")
            print("   → Live Activity と pollingTask は維持。フォアグラウンド復帰時に再開されます")
            self?.endBackgroundTask()
        }
        print("✅ バックグラウンドタスクを開始しました (ID: \(backgroundTaskID))")
#endif
    }
    
    /// バックグラウンドタスクを終了し、システムにリソースを返却する
    func endBackgroundTask() {
#if !os(watchOS) && canImport(UIKit)
        guard let sharedApplication = UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? UIApplication else {
            return
        }

        if backgroundTaskID != .invalid {
            sharedApplication.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            print("✅ バックグラウンドタスクを終了しました")
        }
#endif
    }

    
    // MARK: - Live Activity 管理
    
    /// 絵本生成の開始時にLive Activityを開始する
    func startActivity(bookTitle: String, childName: String, estimatedSeconds: TimeInterval = 30, storybookId: Int? = nil) {
        // Info.plistで有効化されているか、iOS 16.1+かチェック
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activitiesが許可されていない、またはサポートされていません")
            // Activityが使えなくてもバックグラウンド生成はできるようにする
            beginBackgroundTask()
            return
        }
        
        // 既存のActivityがあれば終了させる
        if currentActivity != nil {
            endActivity(status: "completed", message: "新しい生成が始まりました")
        }
        
        self.generatedBookTitle = bookTitle
        self.estimatedCompletionTime = Date().addingTimeInterval(estimatedSeconds)
        self.storybookId = storybookId
        
        // 静的データ（開始時に決まるもの）
        let attributes = GenerationActivityAttributes(bookTitle: bookTitle, childName: childName)
        
        // 動的データ（変化するもの: 初期状態）
        let initialContentState = GenerationActivityAttributes.ContentState(
            progressText: "ストーリーを考え中...",
            progressValue: 0.1,
            estimatedEndTime: estimatedCompletionTime,
            status: "in_progress"
        )
        
        do {
            // Activityの開始（pushType: .token でサーバーからの更新を有効化）
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: .token
            )
            self.currentActivity = activity
            print("✅ Live Activityを開始しました: \(activity.id)")
            
            // pushTokenの更新を監視し、バックエンドに送信
            observePushTokenUpdates(for: activity)
            
            // 同時にバックグラウンドタスクも開始
            beginBackgroundTask()
            
            // 擬似的な進捗タイマーを開始（APIの応答を待たずにUIを進めるため）
            startProgressTimer(totalSeconds: estimatedSeconds)
            
        } catch {
            print("❌ Live Activityの開始に失敗: \(error.localizedDescription)")
            beginBackgroundTask()
        }
    }
    
    /// Storybook IDが後から分かった場合にセットし、実際のポーリングを開始する
    func updateStorybookId(_ id: Int) {
        self.storybookId = id
        // 実際のポーリングタスクを開始する（擬似タイマーはそのままか、ここで止めても良い）
        startPollingTask()
    }
    
    /// 進捗状況をシステムに更新（UIアニメーション）
    func updateProgress(progressText: String, progressValue: Double) {
        guard let activity = currentActivity else { return }
        
        let updatedState = GenerationActivityAttributes.ContentState(
            progressText: progressText,
            progressValue: progressValue,
            estimatedEndTime: self.estimatedCompletionTime,
            status: "in_progress"
        )
        
        Task {
            // アラート（Dynamic Islandをポンッと揺らすなど）を付けたい場合は alertConfiguration を設定可能
            await activity.update(
                ActivityContent<GenerationActivityAttributes.ContentState>(
                    state: updatedState,
                    staleDate: nil
                )
            )
        }
    }
    
    /// 生成が完了、または失敗した時にActivityを終了させる
    func endActivity(status: String, message: String) {
        // 擬似タイマーを止める
        stopProgressTimer()
        // ポーリングタスクも停止（生成完了/失敗時のみ）
        stopPollingTask()
        // pushToken監視タスクも停止
        pushTokenTask?.cancel()
        pushTokenTask = nil
        
        guard let activity = currentActivity else {
            // Activityが元々無かったとしてもバックグラウンドタスクは終了させる
            endBackgroundTask()
            return
        }
        
        let finalState = GenerationActivityAttributes.ContentState(
            progressText: message,
            progressValue: status == "completed" ? 1.0 : 0.0,
            estimatedEndTime: Date(),
            status: status
        )
        
        Task {
            // 完了状態に更新し、Activityを終了。
            // ユーザーが通知をスワイプして消すか、システムが自動で消すまで残る（default）
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
            self.currentActivity = nil
            print("✅ Live Activityを終了(\(status))しました")
            
            // Activity終了と同時に、バックグラウンドでの保護も終了
            self.endBackgroundTask()
        }
    }
    
    // MARK: - 擬似的な進捗タイマー
    
    private func startProgressTimer(totalSeconds: TimeInterval) {
        stopProgressTimer()
        var currentSeconds = 0.0
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // 実際のポーリングタスクが動いていて、進捗が更新されている場合は無視するようにしても良い
            // ここでは簡易的に、storybookIdがセットされるまでは動かす
            guard self.storybookId == nil else { return }
            
            currentSeconds += 3.0
            
            // 90%までは擬似的に進める（残りの10%は実際のAPI完了時に埋める）
            let ratio = min((currentSeconds / totalSeconds) * 0.9, 0.9)
            
            let text: String
            switch ratio {
            case 0.0..<0.3: text = "ストーリーを執筆中..."
            case 0.3..<0.6: text = "イラストを描画中..."
            case 0.6..<0.9: text = "絵本を製本中..."
            default: text = "もうすぐ完成します..."
            }
            
            self.updateProgress(progressText: text, progressValue: ratio)
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        // 注意: pollingTask はここではキャンセルしない
        // endActivity() から明示的に stopPollingTask() を呼ぶ
    }
    
    /// ポーリングタスクを明示的に停止する（生成完了/失敗時にのみ呼ぶ）
    private func stopPollingTask() {
        pollingTask?.cancel()
        pollingTask = nil
        print("⏹️ LiveActivityManager: ポーリングタスクを停止しました")
    }
    
    // MARK: - 実進捗ポーリング （バックグラウンド対応）
    private func startPollingTask() {
        guard let storybookId = storybookId else { return }
        pollingTask?.cancel()
        
        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    guard let fetcher = self.progressFetcher else {
                        print("⚠️ LiveActivityManager: progressFetcherが設定されていません")
                        return
                    }
                    
                    let progress = try await fetcher(storybookId)
                    
                    // APIからの進捗値（0〜100）を15%-95%の範囲に（0.15〜0.95）
                    let rawAPIProgress = 0.15 + (0.80 * (Double(progress.progressPercent) / 100.0))
                    let targetFromAPI = min(rawAPIProgress, 0.95)  // 95%で上限
                    
                    let status = progress.status.lowercased()
                    
                    if status == "completed" {
                        self.endActivity(status: "completed", message: "絵本が完成しました！")
                        break
                    } else if status == "failed" {
                        self.endActivity(status: "error", message: "エラーが発生しました")
                        break
                    } else {
                        // 進行中
                        let currentPage = progress.currentPage
                        let totalPages = progress.totalPages
                        let stepMessage = "絵を描いています... (\(max(currentPage, 1))/\(totalPages)ページ)"
                        
                        self.updateProgress(progressText: stepMessage, progressValue: targetFromAPI)
                    }
                    
                } catch {
                    print("⚠️ LiveActivityManager: 進捗取得エラー: \(error)")
                }
                
                // 3秒に1回ポーリング
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }
    
    // MARK: - ActivityKit Push Token 管理
    
    /// Live ActivityのpushTokenをバックエンドに送信するクロージャー（メインアプリから注入）
    /// パラメータ: (pushToken: String, storybookId: Int)
    public var pushTokenSender: ((String, Int) async -> Void)?
    
    /// Live ActivityのpushTokenUpdatesを監視し、トークンをバックエンドに送信
    private func observePushTokenUpdates(for activity: Activity<GenerationActivityAttributes>) {
        pushTokenTask?.cancel()
        pushTokenTask = Task {
            for await tokenData in activity.pushTokenUpdates {
                let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
                print("🔑 Live Activity pushToken取得: \(tokenString.prefix(20))...")
                
                guard let storybookId = self.storybookId else {
                    print("⚠️ storybookIdが未設定のため、pushToken送信をスキップ")
                    continue
                }
                
                if let sender = self.pushTokenSender {
                    await sender(tokenString, storybookId)
                } else {
                    print("⚠️ pushTokenSenderが未設定のため、pushToken送信をスキップ")
                }
            }
        }
    }
}
