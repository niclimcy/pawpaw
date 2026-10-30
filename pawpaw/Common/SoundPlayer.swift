//
//  SoundPlayer.swift
//  pawpaw
//

import AVFoundation

enum GameSound: CaseIterable {
    case squeak
    case rustle
    case flutter
    case chirp
    case swish
    case whisper
    case catchPop
}

/// Sounds are synthesized at launch; there are no audio assets.
final class SoundPlayer {
    static let shared = SoundPlayer()

    private static let sampleRate = 44_100.0
    /// Players per sound, so two critters can make the same sound at different pans.
    private static let voices = 3
    private var players: [GameSound: [AVAudioPlayer]] = [:]
    private var nextVoice: [GameSound: Int] = [:]

    private init() {
        // Ambient: mixes with other audio and respects the silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        for sound in GameSound.allCases {
            let data = Self.wav(from: Self.samples(for: sound))
            players[sound] = (0..<Self.voices).compactMap { _ -> AVAudioPlayer? in
                let player = try? AVAudioPlayer(data: data)
                player?.prepareToPlay()
                return player
            }
        }
    }

    /// `pan` runs from -1 (left) to 1 (right).
    func play(_ sound: GameSound, pan: Float = 0) {
        guard let pool = players[sound], !pool.isEmpty else { return }
        let index = nextVoice[sound, default: 0] % pool.count
        nextVoice[sound] = (index + 1) % pool.count
        let player = pool[index]
        player.pan = max(-1, min(1, pan))
        player.currentTime = 0
        player.play()
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
        }
    }

    // MARK: Synthesis
    private static func samples(for sound: GameSound) -> [Float] {
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
        case .catchPop:
            return chirp(from: 5_000, to: 2_600, duration: 0.09, volume: 0.5)
                + chirp(from: 3_600, to: 2_000, duration: 0.11, volume: 0.45)
        }
    }

    /// Sine sweep from `start` to `end` Hz.
    private static func chirp(from start: Double, to end: Double, duration: Double, volume: Float) -> [Float] {
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
    private static func noiseBursts(duration: Double, burstRate: Double, volume: Float, bright: Bool = false) -> [Float] {
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
    private static func wav(from samples: [Float]) -> Data {
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
