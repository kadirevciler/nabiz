import Foundation
import Security
import Observation

enum AIProvider: String, CaseIterable, Identifiable {
    case openai, claude, gemini, deepseek, glm, openrouter
    var id: String { rawValue }

    var name: String {
        switch self {
        case .openai: "OpenAI"
        case .claude: "Claude"
        case .gemini: "Gemini"
        case .deepseek: "DeepSeek"
        case .glm: "GLM (Z.ai)"
        case .openrouter: "OpenRouter"
        }
    }

    var company: String {
        switch self {
        case .openai: "OpenAI"
        case .claude: "Anthropic"
        case .gemini: "Google"
        case .deepseek: "DeepSeek"
        case .glm: "Zhipu AI · Z.ai"
        case .openrouter: "OpenRouter"
        }
    }

    /// Logo dosyası adı (Resources/Logos/<logo>.png).
    var logo: String { rawValue }

    var modelPlaceholder: String {
        switch self {
        case .openai: "gpt-5"
        case .claude: "claude-opus-5-5"
        case .gemini: "gemini-2.5-pro"
        case .deepseek: "deepseek-chat"
        case .glm: "glm-4.6"
        case .openrouter: "anthropic/claude-opus-5-5"
        }
    }

    var keyPage: URL {
        URL(string: [
            .openai: "https://platform.openai.com/api-keys",
            .claude: "https://console.anthropic.com/settings/keys",
            .gemini: "https://aistudio.google.com/apikey",
            .deepseek: "https://platform.deepseek.com/api_keys",
            .glm: "https://z.ai/manage-apikey/apikey-list",
            .openrouter: "https://openrouter.ai/keys",
        ][self]!)!
    }

    /// Durum raporunu yapıştırmak için sohbet arayüzü.
    var chatURL: URL {
        URL(string: [
            .openai: "https://chatgpt.com/",
            .claude: "https://claude.ai/new",
            .gemini: "https://gemini.google.com/app",
            .deepseek: "https://chat.deepseek.com/",
            .glm: "https://chat.z.ai/",
            .openrouter: "https://openrouter.ai/chat",
        ][self]!)!
    }

    var chatName: String {
        switch self {
        case .openai: "ChatGPT"
        case .glm: "Z.ai Chat"
        default: name
        }
    }
}

/// API anahtarlarını macOS Anahtar Zinciri'nde saklar.
enum KeychainStore {
    private static let service = "com.kadir.nabiz.ai"

    private static func base(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    @discardableResult
    static func save(_ value: String, for account: String) -> Bool {
        delete(account)
        var q = base(account)
        q[kSecValueData as String] = Data(value.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        return SecItemAdd(q as CFDictionary, nil) == errSecSuccess
    }

    static func load(_ account: String) -> String? {
        var q = base(account)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data else { return nil }
        return String(data: d, encoding: .utf8)
    }

    static func delete(_ account: String) {
        SecItemDelete(base(account) as CFDictionary)
    }
}

enum AIPhase: Equatable {
    case idle
    case running(AIProvider)
    case done(provider: AIProvider, model: String, text: String, seconds: Int)
    case failed(String)
}

@Observable @MainActor
final class AIService {
    var provider: AIProvider {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: "ai.provider") }
    }
    var phase: AIPhase = .idle
    /// Kayıtlı anahtarı olan sağlayıcılar (anahtarın kendisi bellekte tutulmaz).
    var savedKeys: Set<AIProvider> = []

    init() {
        provider = AIProvider(rawValue: UserDefaults.standard.string(forKey: "ai.provider") ?? "") ?? .claude
        savedKeys = Set(AIProvider.allCases.filter { KeychainStore.load($0.rawValue) != nil })
    }

    func model(for p: AIProvider) -> String { UserDefaults.standard.string(forKey: "ai.model.\(p.rawValue)") ?? "" }
    func setModel(_ m: String, for p: AIProvider) { UserDefaults.standard.set(m, forKey: "ai.model.\(p.rawValue)") }

    func saveKey(_ key: String, for p: AIProvider) {
        let k = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty, KeychainStore.save(k, for: p.rawValue) else { return }
        savedKeys.insert(p)
    }

    func removeKey(for p: AIProvider) {
        KeychainStore.delete(p.rawValue)
        savedKeys.remove(p)
    }

    var isRunning: Bool { if case .running = phase { return true }; return false }

    func analyze(report: String, instructions: String) {
        let p = provider
        let model = self.model(for: p).trimmingCharacters(in: .whitespaces)
        guard let key = KeychainStore.load(p.rawValue), !key.isEmpty else {
            phase = .failed(L("Önce \(p.name) API anahtarını kaydedin.", "Save your \(p.name) API key first.")); return
        }
        guard !model.isEmpty else {
            phase = .failed(L("Model adını yazın (örn. \(p.modelPlaceholder)).", "Enter a model name (e.g. \(p.modelPlaceholder)).")); return
        }
        phase = .running(p)
        let start = Date()
        Task {
            do {
                let text = try await AIClient.complete(provider: p, key: key, model: model, system: instructions, user: report)
                phase = .done(provider: p, model: model, text: text, seconds: Int(Date().timeIntervalSince(start)))
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}

struct AIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Sağlayıcılara ham HTTP istekleri (Swift için resmi SDK yok).
enum AIClient {
    static func complete(provider: AIProvider, key: String, model: String, system: String, user: String) async throws -> String {
        var req: URLRequest
        var body: [String: Any]

        switch provider {
        case .claude:
            req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            req.setValue(key, forHTTPHeaderField: "x-api-key")
            req.setValue("2026-10-21", forHTTPHeaderField: "anthropic-version")
            body = ["model": model, "max_tokens": 16000, "system": system,
                    "messages": [["role": "user", "content": user]]]
        case .gemini:
            let m = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? model
            req = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(m):generateContent")!)
            req.setValue(key, forHTTPHeaderField: "x-goog-api-key")
            body = ["systemInstruction": ["parts": [["text": system]]],
                    "contents": [["role": "user", "parts": [["text": user]]]]]
        case .openai, .deepseek, .glm, .openrouter:
            let url = [
                AIProvider.openai: "https://api.openai.com/v1/chat/completions",
                .deepseek: "https://api.deepseek.com/chat/completions",
                .glm: "https://api.z.ai/api/paas/v4/chat/completions",
                .openrouter: "https://openrouter.ai/api/v1/chat/completions",
            ][provider]!
            req = URLRequest(url: URL(string: url)!)
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            if provider == .openrouter {
                req.setValue("https://github.com/kadirevciler/nabiz", forHTTPHeaderField: "HTTP-Referer")
                req.setValue("Nabiz", forHTTPHeaderField: "X-Title")
            }
            body = ["model": model, "messages": [["role": "system", "content": system], ["role": "user", "content": user]]]
        }

        req.httpMethod = "POST"
        req.timeoutInterval = 300
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]

        guard (200..<300).contains(status) else {
            throw AIError(message: "\(provider.name) · HTTP \(status): " + errorText(json, data))
        }

        let text: String?
        switch provider {
        case .claude:
            if (json["stop_reason"] as? String) == "refusal" {
                throw AIError(message: L("Model bu isteği yanıtlamayı reddetti.", "The model declined this request."))
            }
            text = (json["content"] as? [[String: Any]])?
                .filter { ($0["type"] as? String) == "text" }
                .compactMap { $0["text"] as? String }.joined(separator: "\n")
        case .gemini:
            let parts = ((json["candidates"] as? [[String: Any]])?.first?["content"] as? [String: Any])?["parts"] as? [[String: Any]]
            text = parts?.compactMap { $0["text"] as? String }.joined(separator: "\n")
        default:
            text = ((json["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any])?["content"] as? String
        }
        guard let t = text, !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIError(message: L("Boş yanıt geldi.", "Empty response.") + " " + String(decoding: data.prefix(300), as: UTF8.self))
        }
        return t
    }

    private static func errorText(_ json: [String: Any], _ data: Data) -> String {
        if let e = json["error"] as? [String: Any], let m = e["message"] as? String { return m }
        if let m = json["error"] as? String { return m }
        if let m = json["message"] as? String { return m }
        return String(decoding: data.prefix(300), as: UTF8.self)
    }
}
