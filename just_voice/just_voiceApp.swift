//
//  just_voiceApp.swift
//  just_voice
//
//  Created by Kisoon Kwon on 11/28/24.
//

import Foundation
import AVFoundation
import SwiftUI

class AudioPlayer: ObservableObject {
    var justVoiceHandle: UnsafeMutablePointer<just_voice_handle_t?>? = nil
    var audioEngine: AVAudioEngine!
    var playerNode: AVAudioPlayerNode!
    var audioFile: AVAudioFile!
    var audioBuffer: AVAudioPCMBuffer!
    var currentSampleIndex = 0
    var isPlaying = false
    let blockSize = 512
    
    @Published var noiseReductionIntensity: Float = 0.5
    
    init() {
        loadAudioFile()
        setupJustVoiceAPI()
        setupAudioEngine()
    }
    
    func setupJustVoiceAPI() {
        var config = just_voice_config_t()
        config.numInputChannels = 1
        config.numOutputChannels = 1
        config.sampleRate = UInt32(Float(audioFile.processingFormat.sampleRate)) // Use content's sample rate
        config.samplesPerBlock = UInt32(blockSize)
        
        var params = just_voice_params_t()
        params.noiseReductionIntensity = 0.5  // Default value
        
        // Create Just Voice handle
        let createResult = JV_CREATE(&justVoiceHandle)
        if createResult != JV_SUCCESS {
            print("Error creating Just Voice handle.")
            return
        }
        
        let setupResult = JV_SETUP(justVoiceHandle, &config, &params)
        if setupResult != JV_SUCCESS {
            print("Error setting up Just Voice.")
            return
        }
    }

    func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        let timePitch = AVAudioUnitTimePitch()
        timePitch.rate = 1.0 // Set playback speed to 1x (can adjust later if needed)

        audioEngine.attach(playerNode)
        audioEngine.attach(timePitch)
        
        // Dynamically set the number of channels and sample rate based on the loaded audio file
        let channelCount = audioFile.processingFormat.channelCount
        let sampleRate = audioFile.processingFormat.sampleRate
        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: UInt32(channelCount))!
        
        // Connect playerNode -> timePitch -> mainMixerNode
        audioEngine.connect(playerNode, to: timePitch, format: outputFormat)
        audioEngine.connect(timePitch, to: audioEngine.mainMixerNode, format: outputFormat)
        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    func loadAudioFile() {
        guard let url = Bundle.main.url(forResource: "sunrise-serenade-203778", withExtension: "wav") else {
            print("Audio file not found.")
            return
        }
        
        do {
            audioFile = try AVAudioFile(forReading: url)
            let frameCount = AVAudioFrameCount(audioFile.length)
            audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount)!
            try audioFile.read(into: audioBuffer)
            print("Loaded audio file.")
        } catch {
            print("Error loading audio file: \(error)")
        }
    }

    func playPCMDataBlock() {
        if currentSampleIndex >= audioBuffer.frameLength {
            print("Reached end of audio data.")
            stopPlayback()
            return
        }
        
        let startSample = currentSampleIndex
        let endSample = min(currentSampleIndex + blockSize, Int(audioBuffer.frameLength))
        
        _ = AVAudioFrameCount(endSample - startSample)
        
        // Create a buffer slice for the block
        let blockBuffer = audioBuffer.slice(from: startSample, to: endSample)

        // Get the first channel's data from the blockBuffer
        guard let inputData = blockBuffer.floatChannelData?[0] else {
            print("Error: No channel data found in the buffer.")
            return
        }

        // Prepare an output buffer for the processed audio
        var outputData = Array(repeating: Float(0), count: blockSize)
        
        // Process the audio using Just Voice API
        let processResult = JV_PROCESS(justVoiceHandle, inputData, &outputData, UInt32(blockSize))
        if processResult != JV_SUCCESS {
            print("Error processing audio block(%d).", processResult)
        }

        // Create an AVAudioPCMBuffer from the processed output data
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: blockBuffer.format, frameCapacity: AVAudioFrameCount(outputData.count))!
        outputBuffer.frameLength = AVAudioFrameCount(outputData.count)
        for channel in 0..<outputBuffer.format.channelCount {
            let outputChannelData = outputBuffer.floatChannelData![Int(channel)]
            for i in 0..<outputData.count {
                outputChannelData[i] = outputData[i]
            }
        }

        // Schedule the buffer for playback
        playerNode.scheduleBuffer(outputBuffer) {
            DispatchQueue.main.async {
                self.currentSampleIndex = endSample
                if self.isPlaying {
                    self.playPCMDataBlock() // Recursively call for the next block
                }
            }
        }

        // If player is not already playing, start it
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    func updateNoiseReductionIntensity() {
        var params = just_voice_params_t()
        params.noiseReductionIntensity = noiseReductionIntensity
        
        let updateResult = JV_UPDATE(justVoiceHandle, &params)
        if updateResult != JV_SUCCESS {
            print("Error updating noise reduction intensity.")
        }
    }

    func startPlayback() {
        if !isPlaying {
            isPlaying = true
            playPCMDataBlock()
        }
    }

    func stopPlayback() {
        if isPlaying {
            playerNode.stop()
            isPlaying = false
            currentSampleIndex = 0
            print("Playback stopped.")
        }
    }
}

extension AVAudioPCMBuffer {
    func slice(from start: Int, to end: Int) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(end - start)
        let buffer = AVAudioPCMBuffer(pcmFormat: self.format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        // Copy data for all channels
        for channel in 0..<self.format.channelCount {
            let sourceChannelData = self.floatChannelData![Int(channel)]
            let destinationChannelData = buffer.floatChannelData![Int(channel)]
            for i in start..<end {
                destinationChannelData[i - start] = sourceChannelData[i]
            }
        }
        
        return buffer
    }
}

struct ContentView: View {
    @StateObject private var audioPlayer = AudioPlayer()

    var body: some View {
        VStack {
            Text("Audio Processor with Noise Reduction")
                            .font(.largeTitle)
                            .padding()

                        Slider(value: $audioPlayer.noiseReductionIntensity, in: 0...1, step: 0.01)
                            .padding()
                            .onChange(of: audioPlayer.noiseReductionIntensity) {
                                audioPlayer.updateNoiseReductionIntensity()
                            }

                        Text("Noise Reduction Intensity: \(audioPlayer.noiseReductionIntensity, specifier: "%.2f")")
                            .padding()

            Text("Audio Player")
                .font(.largeTitle)
                .padding()
            
            HStack {
                Button(action: {
                    audioPlayer.startPlayback()
                }) {
                    Text("Play")
                        .font(.title)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    audioPlayer.stopPlayback()
                }) {
                    Text("Stop")
                        .font(.title)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}
