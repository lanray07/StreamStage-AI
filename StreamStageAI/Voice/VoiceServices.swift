import AVFoundation
import Foundation
import Observation
import Speech

struct VoiceAnalysisResult {
    var fillerWordCount: Int
    var estimatedWordsPerMinute: Int
    var confidenceScore: Int
    var notes: [String]
}

struct VoiceAnalysisService {
    private let fillerWords: Set<String> = ["um", "uh", "like", "basically", "actually", "literally", "you know"]

    func analyze(transcript: String) -> VoiceAnalysisResult {
        let words = transcript
            .lowercased()
            .split { !$0.isLetter }
            .map(String.init)

        let fillerCount = words.filter { fillerWords.contains($0) }.count
        let estimatedPace = words.isEmpty ? 0 : min(190, max(95, words.count * 6))
        let confidence = max(52, min(98, 88 - fillerCount * 2 + (words.count > 20 ? 5 : 0)))

        let notes = [
            fillerCount == 0 ? "Clean delivery with low filler-word risk." : "Filler-word placeholder detected \(fillerCount) possible moments.",
            estimatedPace > 160 ? "Pace estimate is energetic. Add short pauses after key claims." : "Pace estimate leaves room for audience comprehension.",
            "Confidence scoring is local placeholder analysis until the remote coach is connected."
        ]

        return VoiceAnalysisResult(
            fillerWordCount: fillerCount,
            estimatedWordsPerMinute: estimatedPace,
            confidenceScore: confidence,
            notes: notes
        )
    }
}

@MainActor
@Observable
final class SpeechRecognitionService {
    var transcript = ""
    var editedTranscript = ""
    var isRecording = false
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var errorMessage: String?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestAuthorization() async {
        authorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func start() async {
        if authorizationStatus == .notDetermined {
            await requestAuthorization()
        }

        guard authorizationStatus == .authorized else {
            errorMessage = "Speech recognition permission is required for voice rehearsal."
            return
        }

        do {
            try startRecognition()
        } catch {
            errorMessage = error.localizedDescription
            stop()
        }
    }

    func pause() {
        stop()
        editedTranscript = transcript
    }

    func resume() async {
        await start()
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    func commitEdit(_ text: String) {
        editedTranscript = text
        transcript = text
    }

    private func startRecognition() throws {
        stop()

        transcript = editedTranscript.isEmpty ? transcript : editedTranscript

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognizer is unavailable right now."
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    self?.transcript = result.bestTranscription.formattedString
                    self?.editedTranscript = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self?.stop()
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }
}

@MainActor
@Observable
final class VoiceRecordingService {
    var hasMicrophonePermission = false
    var isRecording = false
    var errorMessage: String?

    func requestMicrophonePermission() async {
        hasMicrophonePermission = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startPlaceholderRecording() async {
        if !hasMicrophonePermission {
            await requestMicrophonePermission()
        }

        guard hasMicrophonePermission else {
            errorMessage = "Microphone permission is required for live rehearsal."
            return
        }

        isRecording = true
    }

    func stopPlaceholderRecording() {
        isRecording = false
    }
}

@MainActor
@Observable
final class WaveformAnimationManager {
    var samples: [Double] = Array(repeating: 0.25, count: 34)
    private var timer: Timer?

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.samples = (0..<34).map { index in
                    let phase = Double(index) / 34.0
                    let pulse = sin(Date().timeIntervalSince1970 * 5.5 + phase * 8.0)
                    return max(0.12, min(1.0, 0.42 + pulse * 0.25 + Double.random(in: -0.12...0.18)))
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        samples = Array(repeating: 0.18, count: 34)
    }
}

@MainActor
@Observable
final class AudioLevelMeter {
    var normalizedLevel: Double = 0.18
    private var timer: Timer?

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.normalizedLevel = Double.random(in: 0.18...0.96)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        normalizedLevel = 0.18
    }
}
