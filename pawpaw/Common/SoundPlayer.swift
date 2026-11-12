//
//  SoundPlayer.swift
//  pawpaw
//

import AVFoundation

nonisolated enum GameSound: CaseIterable, Sendable {
    case squeak
    case rustle
    case flutter
    case chirp
    case swish
    case whisper
    case tweet
    case skitter
    case catchPop
}

/// Sounds are synthesized at launch; there are no audio assets.
final class SoundPlayer {
    static let shared = SoundPlayer()

    private nonisolated static let sampleRate = 44_100.0
    /// Players per sound, so two critters can make the same sound at different pans.
    private nonisolated static let voices = 3
    private let mixer = Mixer()

    private init() {
        mixer.load()
    }

    /// `pan` runs from -1 (left) to 1 (right).
    func play(_ sound: GameSound, pan: Float = 0) {
        mixer.play(sound, pan: max(-1, min(1, pan)))
    }

    func playAppear(for kind: TargetKind, pan: Float = 0) {
        switch kind {
        case .mouse: play(.squeak, pan: pan)
        case .bug: play(.rustle, pan: pan)
        case .butterfly: play(.flutter, pan: pan)
        case .cricket: play(.chirp, pan: pan)
        case .feather: play(.swish, pan: pan)
        case .laser: break
        case .fish: play(.swish, pan: pan)
        case .ribbon: play(.whisper, pan: pan)
        case .bird: play(.tweet, pan: pan)
        case .lizard: play(.skitter, pan: pan)
        }
    }

    /// `play()` can reactivate the audio session, which blocks, so all player calls stay off the main thread.
    private nonisolated final class Mixer: @unchecked Sendable {
        private let queue = DispatchQueue(label: "pawpaw.sound", qos: .userInitiated)
        private var players: [GameSound: [AVAudioPlayer]] = [:]
        private var nextVoice: [GameSound: Int] = [:]

        func load() {
            queue.async {
                // Ambient: mixes with other audio and respects the silent switch.
                try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try? AVAudioSession.sharedInstance().setActive(true)
                for sound in GameSound.allCases {
                    let data = SoundPlayer.wav(from: SoundPlayer.samples(for: sound))
                    self.players[sound] = (0..<SoundPlayer.voices).compactMap { _ in
                        let player = try? AVAudioPlayer(data: data)
                        player?.prepareToPlay()
                        return player
                    }
                }
            }
        }

        func play(_ sound: GameSound, pan: Float) {
            queue.async {
                guard let pool = self.players[sound], !pool.isEmpty else { return }
                let index = self.nextVoice[sound, default: 0] % pool.count
                self.nextVoice[sound] = (index + 1) % pool.count
                let player = pool[index]
                player.pan = pan
                player.currentTime = 0
                player.play()
            }
        }
    }

    // MARK: Synthesis
    private nonisolated static func samples(for sound: GameSound) -> [Float] {
        switch sound {
        case .squeak:
            return chirp(from: 3_200, to: 4_800, duration: 0.14, volume: 0.5)
        case .rustle:
            return noiseBursts(duration: 0.4, burstRate: 14, volume: 0.45, bright: true)
        case .flutter:
            return noiseBursts(duration: 0.35, burstRate: 28, volume: 0.32, bright: true)
        case .chirp:
            let trill = chirp(from: 4_200, to: 4_400, duration: 0.05, volume: 0.35)
            let gap = [Float](repeating: 0, count: Int(0.03 * sampleRate))
            return trill + gap + trill + gap + trill
        case .swish:
            return noiseBursts(duration: 0.3, burstRate: 4, volume: 0.15)
        case .whisper:
            // One long, soft swoosh, like a string drawn across the floor.
            return noiseBursts(duration: 0.5, burstRate: 1, volume: 0.13)
        case .tweet:
            // A falling "tsee" then a rising "tweet", unlike the cricket's flat trill.
            let gap = [Float](repeating: 0, count: Int(0.05 * sampleRate))
            return chirp(from: 6_200, to: 3_800, duration: 0.08, volume: 0.3)
                + gap
                + chirp(from: 3_600, to: 5_600, duration: 0.06, volume: 0.3)
                + chirp(from: 5_600, to: 4_400, duration: 0.05, volume: 0.25)
        case .skitter:
            // Shorter and lighter than the rustle, like small feet in dry leaves.
            return noiseBursts(duration: 0.25, burstRate: 20, volume: 0.22)
        case .catchPop:
            return chirp(from: 5_000, to: 2_600, duration: 0.09, volume: 0.5)
                + chirp(from: 3_600, to: 2_000, duration: 0.11, volume: 0.45)
        }
    }

    /// Sine sweep from `start` to `end` Hz.
    private nonisolated static func chirp(
        from start: Double, to end: Double, duration: Double, volume: Float
    )
        -> [Float]
    {
        let count = Int(duration * sampleRate)
        var phase = 0.0
        return (0..<count).map { index in
            let progress = Double(index) / Double(count)
            phase += 2 * .pi * (start + (end - start) * progress) / sampleRate
            let envelope = Float(sin(.pi * progress))
            return Float(sin(phase)) * envelope * volume
        }
    }

    /// High-passed noise pulsing at `burstRate` Hz.
    /// `bright` leans it toward 6–12 kHz, where cats hear best.
    private nonisolated static func noiseBursts(
        duration: Double, burstRate: Double, volume: Float, bright: Bool = false
    ) -> [Float] {
        let count = Int(duration * sampleRate)
        // Bright: a steeper high-pass, then a gentle low-pass so the top end doesn't hiss.
        let highPass: Float = bright ? 0.95 : 0.6
        let smoothing: Float = bright ? 0.6 : 1
        var previous: Float = 0
        var smoothed: Float = 0
        return (0..<count).map { index in
            let time = Double(index) / sampleRate
            let progress = time / duration
            let pulse = Float(max(0, sin(2 * .pi * burstRate * time)))
            let envelope = Float(sin(.pi * progress)) * pulse
            let noise = Float.random(in: -1...1)
            let crisp = noise - previous * highPass
            previous = noise
            smoothed += (crisp - smoothed) * smoothing
            return smoothed * envelope * volume
        }
    }

    /// 16-bit mono PCM WAV.
    private nonisolated static func wav(from samples: [Float]) -> Data {
        let byteRate = UInt32(sampleRate) * 2
        let dataSize = UInt32(samples.count * 2)
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        data.append(contentsOf: Array("RIFF".utf8))
        append(36 + dataSize)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        append(UInt32(16))
        append(UInt16(1))
        append(UInt16(1))
        append(UInt32(sampleRate))
        append(byteRate)
        append(UInt16(2))
        append(UInt16(16))
        data.append(contentsOf: Array("data".utf8))
        append(dataSize)
        for sample in samples {
            append(Int16(max(-1, min(1, sample)) * Float(Int16.max)))
        }
        return data
    }
}
