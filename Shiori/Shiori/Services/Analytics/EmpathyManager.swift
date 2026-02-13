// EmpathyManager.swift
// 共感（いいね）データの管理
// Firebase Firestore との同期を担当する（MVP版はローカルストレージ）

import Foundation

/// 共感データの管理マネージャ
/// MVP版ではUserDefaultsに保存し、将来的にFirestoreと同期する
final class EmpathyManager {

    // MARK: - ストレージキー
    private let storageKey = "shiori_empathy_marks"

    // MARK: - ローカルキャッシュ
    private var marks: [EmpathyMark] = []

    // MARK: - 初期化

    init() {
        loadMarks()
    }

    // MARK: - CRUD

    /// 共感マークを追加する
    /// 同じ位置に既存のマークがある場合はカウントをインクリメント
    func addEmpathy(_ mark: EmpathyMark) {
        // 既存マークの検索
        if let index = marks.firstIndex(where: {
            $0.bookId == mark.bookId &&
            $0.pageIndex == mark.pageIndex &&
            $0.textRangeStart == mark.textRangeStart &&
            $0.textRangeEnd == mark.textRangeEnd
        }) {
            marks[index].count += 1
        } else {
            marks.append(mark)
        }
        saveMarks()
    }

    /// 指定した書籍・ページの共感マークを取得する
    func getMarks(for bookId: UUID, page: Int) -> [EmpathyMark] {
        marks.filter { $0.bookId == bookId && $0.pageIndex == page }
    }

    /// 指定した書籍の全共感マークを取得する
    func getAllMarks(for bookId: UUID) -> [EmpathyMark] {
        marks.filter { $0.bookId == bookId }
    }

    // MARK: - 永続化（UserDefaults — MVP版）

    /// ローカルストレージから読み込む
    private func loadMarks() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([EmpathyMark].self, from: data)
        else { return }
        marks = decoded
    }

    /// ローカルストレージに保存する
    private func saveMarks() {
        guard let data = try? JSONEncoder().encode(marks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // MARK: - Firebase同期（将来実装）

    /// Firestoreとの同期（プレースホルダー）
    /// MVP後にFirebase SDKを統合する際に実装する
    func syncWithFirestore() async {
        // TODO: Firestore から共感データを取得し、ローカルとマージする
        // let db = Firestore.firestore()
        // let snapshot = try await db.collection("empathy").getDocuments()
    }
}
