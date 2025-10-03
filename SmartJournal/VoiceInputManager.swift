import Foundation
import Speech
import AVFoundation
import NaturalLanguage

@MainActor
class VoiceInputManager: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        // Don't check permissions immediately to avoid crashes
        // Permissions will be checked when user actually tries to use voice input
    }
    
    func checkPermissions() {
        // Check current authorization status without requesting
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let audioStatus = AVAudioApplication.shared.recordPermission
        
        DispatchQueue.main.async {
            self.isAuthorized = speechStatus == .authorized && audioStatus == .granted
            
            if speechStatus == .notDetermined {
                // Only request authorization if not determined
                SFSpeechRecognizer.requestAuthorization { status in
                    DispatchQueue.main.async {
                        self.isAuthorized = status == .authorized && audioStatus == .granted
                        if status != .authorized {
                            self.errorMessage = "Speech recognition permission is required for voice input"
                        }
                    }
                }
            } else if speechStatus != .authorized {
                self.errorMessage = "Speech recognition permission is required for voice input"
            }
        }
    }
    
    func startRecording() {
        // Check permissions first
        checkPermissions()
        
        guard isAuthorized else {
            errorMessage = "Speech recognition permission required"
            return
        }
        
        guard !isRecording else { return }
        
        // Reset state
        transcribedText = ""
        errorMessage = nil
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            return
        }
        
        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create speech recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            return
        }
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self.stopRecording()
                }
                return
            }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                
                if result.isFinal {
                    DispatchQueue.main.async {
                        self.stopRecording()
                    }
                }
            }
        }
        
        isRecording = true
        isTranscribing = true
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Stop recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Reset state
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        isTranscribing = false
    }
    
    func clearTranscription() {
        transcribedText = ""
        errorMessage = nil
    }
    
    func appendToTranscription(_ text: String) {
        if transcribedText.isEmpty {
            transcribedText = text
        } else {
            transcribedText += " " + text
        }
    }
    
    // MARK: - Multi-language Support
    
    func detectLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else { return nil }
        return language.rawValue
    }
    
    func getSpeechRecognizer(for language: String) -> SFSpeechRecognizer? {
        let locale = Locale(identifier: language)
        return SFSpeechRecognizer(locale: locale)
    }
    
    func isLanguageSupported(_ language: String) -> Bool {
        let locale = Locale(identifier: language)
        return SFSpeechRecognizer.supportedLocales().contains(locale)
    }
    
    // MARK: - Offline Support
    
    func checkOfflineAvailability() -> Bool {
        return speechRecognizer?.supportsOnDeviceRecognition ?? false
    }
    
    func requestOfflineRecognition() {
        guard let speechRecognizer = speechRecognizer else { return }
        
        if speechRecognizer.supportsOnDeviceRecognition {
            speechRecognizer.defaultTaskHint = .confirmation
        }
    }
}
