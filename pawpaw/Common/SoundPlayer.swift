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
    case catchPop
}

/// Sounds are synthesized at launch; there are no audio assets.
final class SoundPlayer {
    static let shared = SoundPlayer()

    private static let sampleRate = 44_100.0
    private var players: [GameSound: AVAudioPlayer] = [:]

    private init() {
        // Ambient: mixes with other audio and respects the silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        for sound in GameSound.allCases {
            let player = try? AVAudioPlayer(data: Self.wav(from: Self.samples(for: sound)))
            player?.prepareToPlay()
            players[sound] = player
        }
    }

    func play(_ sound: GameSound) {
        guard let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
    }

    func playAppear(for kind: TargetKind) {
        switch kind {
        case .mouse: play(.squeak)
        case .bug: play(.rustle)
        case .butterfly: play(.flutter)
        case .cricket: play(.chirp)
        case .feather: play(.swish)
        case .laser: break
        case .fish: play(.swish)
        }
    }

    // MARK: Synthesis
    private static func samples(for sound: GameSound) -> [Float] {
        switch sound {
        case .squeak:
            return chirp(from: 3_200, to: 4_800, duration: 0.14, volume: 0.5)
        case .rustle:
            return noiseBursts(duration: 0.4, burstRate: 14, volume: 0.35)
        case .flutter:
            return noiseBursts(duration: 0.35, burstRate: 28, volume: 0.25)
        case .chirp:
            let trill = chirp(from: 4_200, to: 4_400, duration: 0.05, volume: 0.35)
            let gap = [Float](repeating: 0, count: Int(0.03 * sampleRate))
            return trill + gap + trill + gap + trill
        case .swish:
            return noiseBursts(duration: 0.3, burstRate: 4, volume: 0.15)
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
    private static func noiseBursts(duration: Double, burstRate: Double, volume: Float) -> [Float] {
        let count = Int(duration * sampleRate)
        var previous: Float = 0
        return (0..<count).map { index in
            let time = Double(index) / sampleRate
            let progress = time / duration
            let pulse = Float(max(0, sin(2 * .pi * burstRate * time)))
            let envelope = Float(sin(.pi * progress)) * pulse
            let noise = Float.random(in: -1...1)
            let crisp = noise - previous * 0.6
            previous = noise
            return crisp * envelope * volume
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
