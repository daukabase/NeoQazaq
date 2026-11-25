//
//  PersonalStore.swift
//  WordSuggestionsEngine
//
//  Words the user taught the keyboard, corrections they undid, and words they ignore.
//  Stored only on the device (the keyboard's own UserDefaults); never sent anywhere.
//  Thread-safe: autocomplete runs on a background task while the action handler runs on main.
//

import Foundation

public final class PersonalStore {
    enum Keys {
        static let learned = "personalStore.learned"
        static let rejected = "personalStore.rejected"
        static let ignored = "personalStore.ignored"
        static let tick = "personalStore.tick"
        static let appliedResetToken = "personalStore.appliedResetToken"
    }

    private let defaults: UserDefaults
    private let maxLearned: Int
    private let maxRejected: Int
    private let lock = NSLock()

    /// Word → last-used tick, for least-recently-used eviction.
    private var learned: [String: Int]
    /// "typed→candidate" → last-used tick.
    private var rejected: [String: Int]
    private var ignored: Set<String>
    private var tick: Int

    public init(defaults: UserDefaults = .standard, maxLearned: Int = 5_000, maxRejected: Int = 2_000) {
        self.defaults = defaults
        self.maxLearned = maxLearned
        self.maxRejected = maxRejected
        learned = defaults.dictionary(forKey: Keys.learned) as? [String: Int] ?? [:]
        rejected = defaults.dictionary(forKey: Keys.rejected) as? [String: Int] ?? [:]
        ignored = Set(defaults.stringArray(forKey: Keys.ignored) ?? [])
        tick = defaults.integer(forKey: Keys.tick)
    }

    // MARK: - Learned words

    public var learnedWords: [String] { locked { Array(learned.keys) } }

    public func isLearned(_ word: String) -> Bool {
        locked { learned[Self.normalize(word)] != nil }
    }

    public func learn(_ word: String) {
        let key = Self.normalize(word)
        guard !key.isEmpty else { return }
        locked {
            tick += 1
            learned[key] = tick
            Self.evict(&learned, limit: maxLearned)
            persist()
        }
    }

    public func unlearn(_ word: String) {
        locked {
            learned[Self.normalize(word)] = nil
            persist()
        }
    }

    // MARK: - Rejected corrections

    public func isRejected(typed: String, candidate: String) -> Bool {
        locked { rejected[Self.pairKey(typed, candidate)] != nil }
    }

    public func reject(typed: String, candidate: String) {
        locked {
            tick += 1
            rejected[Self.pairKey(typed, candidate)] = tick
            Self.evict(&rejected, limit: maxRejected)
            persist()
        }
    }

    // MARK: - Ignored words

    public var ignoredWords: [String] { locked { Array(ignored) } }

    public func isIgnored(_ word: String) -> Bool {
        locked { ignored.contains(Self.normalize(word)) }
    }

    public func ignore(_ word: String) {
        let key = Self.normalize(word)
        guard !key.isEmpty else { return }
        locked {
            ignored.insert(key)
            persist()
        }
    }

    public func removeIgnored(_ word: String) {
        locked {
            ignored.remove(Self.normalize(word))
            persist()
        }
    }

    // MARK: - Reset

    public func reset() {
        locked {
            learned = [:]
            rejected = [:]
            ignored = []
            tick = 0
            persist()
        }
    }

    /// The app can't write the keyboard's storage, but the keyboard can read the app group.
    /// The app writes a new token there when the user taps "Reset learned words"; the keyboard
    /// calls this on launch and wipes its store once per new token.
    public func resetIfRequested(token: String?) {
        guard let token, token != defaults.string(forKey: Keys.appliedResetToken) else { return }
        reset()
        defaults.set(token, forKey: Keys.appliedResetToken)
    }

    // MARK: - Private

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    /// Must be called with the lock held.
    private func persist() {
        defaults.set(learned, forKey: Keys.learned)
        defaults.set(rejected, forKey: Keys.rejected)
        defaults.set(Array(ignored), forKey: Keys.ignored)
        defaults.set(tick, forKey: Keys.tick)
    }

    private static func evict(_ dictionary: inout [String: Int], limit: Int) {
        guard dictionary.count > limit else { return }
        let overflow = dictionary.count - limit
        for (key, _) in dictionary.sorted(by: { $0.value < $1.value }).prefix(overflow) {
            dictionary[key] = nil
        }
    }

    static func normalize(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func pairKey(_ typed: String, _ candidate: String) -> String {
        normalize(typed) + "→" + normalize(candidate)
    }
}
