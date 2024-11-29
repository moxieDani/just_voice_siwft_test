//
//  just_voiceApp.swift
//  just_voice
//
//  Created by Kisoon Kwon on 11/28/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var justVoiceHandle: UnsafeMutablePointer<just_voice_handle_t?>? = nil
    @State private var noiseReductionIntensity: Float = 0.9
    @State private var isProcessed: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var outputFileURL: URL? // 저장된 WAV 파일 경로
    let wavProcessor = WAVProcessor() // WAV 처리 클래스 인스턴스 생성

    var body: some View {
        VStack {
            Text("Just Voice iOS App")
                .font(.largeTitle)
                .padding()

            // 노이즈 제거 강도 슬라이더
            HStack {
                Text("Noise Reduction: \(String(format: "%.2f", noiseReductionIntensity))")
                Slider(value: Binding(
                    get: { Double(noiseReductionIntensity) },
                    set: { newValue in
                        noiseReductionIntensity = Float(newValue)
                        updateNoiseReduction()
                    }
                ), in: 0.0...1.0)
                    .padding()
            }

            // 오디오 처리 버튼
            Button("Process Audio") {
                processAudio()
            }
            .padding()

            // 오디오 재생 버튼
            Button("Play Processed Audio") {
                playSavedAudio()
            }
            .padding()
            .disabled(!isProcessed) // 처리 완료 여부에 따라 활성화
        }
        .onAppear {
            initializeJustVoice()
        }
        .onDisappear {
            destroyJustVoice()
        }
    }

    // Just Voice 초기화
    func initializeJustVoice() {
        let result = JV_CREATE(&justVoiceHandle)
        guard result == JV_SUCCESS else {
            print("Failed to initialize Just Voice")
            return
        }

        var config = just_voice_config_t(numInputChannels: 2, numOutputChannels: 2, sampleRate: 44100, samplesPerBlock: 0)
        var params = just_voice_params_t(noiseReductionIntensity: noiseReductionIntensity)
        let setupResult = JV_SETUP(justVoiceHandle, &config, &params)
        guard setupResult == JV_SUCCESS else {
            print("Failed to set up Just Voice")
            return
        }
    }

    // Just Voice 리소스 해제
    func destroyJustVoice() {
        JV_DESTROY(&justVoiceHandle)
    }

    // 슬라이더 값 변경 시 호출
    func updateNoiseReduction() {
        guard let handle = justVoiceHandle else { return }
        var params = just_voice_params_t(noiseReductionIntensity: noiseReductionIntensity)
        let result = JV_UPDATE(handle, &params)
        if result != JV_SUCCESS {
            print("Failed to update noise reduction intensity")
        }
    }

    // 오디오 처리
        func processAudio() {
            guard let handle = justVoiceHandle else { return }

            // 번들에서 오디오 파일 로드
            guard let path = Bundle.main.path(forResource: "sunrise-serenade-203778", ofType: "wav") else {
                print("Audio file not found in bundle.")
                return
            }

            let url = URL(fileURLWithPath: path)

            do {
                // WAV 파일 데이터를 로드
                let wavData = try Data(contentsOf: url)

                // PCM 데이터로 변환
                var pcmBuffer = wavProcessor.convertToPCM(data: wavData)

                // Just Voice API를 사용하여 오디오 처리
                var outputBuffer = [Float](repeating: 0.0, count: pcmBuffer.count)
                let processResult = JV_PROCESS(handle, &pcmBuffer, &outputBuffer, UInt32(pcmBuffer.count))

                if processResult == JV_SUCCESS {
                    print("Audio processed successfully.")

                    // 처리된 데이터를 WAV 파일로 저장
                    outputFileURL = wavProcessor.saveAsWAV(buffer: outputBuffer)
                    isProcessed = outputFileURL != nil
                } else {
                    print("Audio processing failed with error code: \(processResult)")
                }
            } catch {
                print("Failed to process audio: \(error)")
            }
        }

    // 처리된 WAV 파일 재생
    func playSavedAudio() {
        guard let fileURL = outputFileURL else {
            print("Processed audio file not found.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.play()
            print("Playing processed audio.")
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
}
