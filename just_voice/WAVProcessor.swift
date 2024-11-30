//
//  WAVProcessor.swift
//  just_voice
//
//  Created by Kisoon Kwon on 11/29/24.
//


import Foundation

class WAVProcessor {
    // PCM 데이터 변환 함수
    func convertToPCM(data: Data) -> [Float] {
        var pcmBuffer: [Float] = []

        // WAV 헤더 크기 확인 (44바이트)
        let headerSize = 44
        guard data.count > headerSize else {
            print("Invalid WAV file: Data is too small.")
            return []
        }

        // PCM 데이터 추출 (헤더 이후)
        let pcmData = data[headerSize...]

        // 16비트 PCM 데이터 -> Float 변환
        pcmData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            let int16Buffer = buffer.bindMemory(to: Int16.self)
            pcmBuffer = int16Buffer.map { sample -> Float in
                return Float(sample) / Float(Int16.max) // 정규화
            }
        }

        return pcmBuffer
    }

    // 처리된 PCM 데이터를 WAV 데이터로 변환
    func convertToAudioData(buffer: [Float]) -> Data {
        let sampleRate: Double = 44100
        let channelCount: UInt32 = 2
        let bitDepth = 16

        // Int16 PCM 데이터 생성
        let int16Buffer = buffer.map { sample -> Int16 in
            let clampedSample = max(-1.0, min(1.0, sample))
            return Int16(clampedSample * Float(Int16.max))
        }

        // WAV 헤더 생성
        let header = createWAVHeader(
            sampleRate: sampleRate,
            channelCount: channelCount,
            bitDepth: bitDepth,
            dataSize: int16Buffer.count * MemoryLayout<Int16>.size
        )

        // WAV 데이터 생성
        var wavData = Data(header)
        int16Buffer.withUnsafeBufferPointer { bufferPointer in
            wavData.append(bufferPointer)
        }

        return wavData
    }

    // WAV 헤더 생성 함수
    func createWAVHeader(sampleRate: Double, channelCount: UInt32, bitDepth: Int, dataSize: Int) -> [UInt8] {
        let byteRate = UInt32(sampleRate * Double(Int(channelCount) * bitDepth / 8))
        let blockAlign = UInt16(channelCount * UInt32(bitDepth / 8))

        return [
            // ChunkID: "RIFF"
            0x52, 0x49, 0x46, 0x46, // "RIFF" ASCII
            // ChunkSize: 36 + Subchunk2Size (dataSize)
            UInt8((36 + dataSize) & 0xff),
            UInt8(((36 + dataSize) >> 8) & 0xff),
            UInt8(((36 + dataSize) >> 16) & 0xff),
            UInt8(((36 + dataSize) >> 24) & 0xff),
            // Format: "WAVE"
            0x57, 0x41, 0x56, 0x45, // "WAVE" ASCII
            // Subchunk1ID: "fmt "
            0x66, 0x6d, 0x74, 0x20, // "fmt " ASCII
            // Subchunk1Size: 16 for PCM
            0x10, 0x00, 0x00, 0x00,
            // AudioFormat: 1 (PCM)
            0x01, 0x00,
            // NumChannels
            UInt8(channelCount & 0xff),
            UInt8((channelCount >> 8) & 0xff),
            // SampleRate
            UInt8(UInt32(sampleRate) & 0xff),
            UInt8((UInt32(sampleRate) >> 8) & 0xff),
            UInt8((UInt32(sampleRate) >> 16) & 0xff),
            UInt8((UInt32(sampleRate) >> 24) & 0xff),
            // ByteRate
            UInt8(byteRate & 0xff),
            UInt8((byteRate >> 8) & 0xff),
            UInt8((byteRate >> 16) & 0xff),
            UInt8((byteRate >> 24) & 0xff),
            // BlockAlign
            UInt8(blockAlign & 0xff),
            UInt8((blockAlign >> 8) & 0xff),
            // BitsPerSample
            UInt8(bitDepth & 0xff),
            UInt8((bitDepth >> 8) & 0xff),
            // Subchunk2ID: "data"
            0x64, 0x61, 0x74, 0x61, // "data" ASCII
            // Subchunk2Size: dataSize
            UInt8(dataSize & 0xff),
            UInt8(((dataSize) >> 8) & 0xff),
            UInt8(((dataSize) >> 16) & 0xff),
            UInt8(((dataSize) >> 24) & 0xff)
        ]
    }

    // WAV 파일로 저장
    func saveAsWAV(buffer: [Float]) -> URL? {
        let wavData = convertToAudioData(buffer: buffer)

        // 파일 저장 경로 설정
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("processed_audio.wav")
        do {
            try wavData.write(to: fileURL)
            print("WAV file saved to: \(fileURL.path)")
            return fileURL
        } catch {
            print("Failed to save WAV file: \(error)")
            return nil
        }
    }
}