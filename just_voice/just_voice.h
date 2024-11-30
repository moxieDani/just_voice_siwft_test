/*******************************************************************************
 *  Copyright 2023 Gaudio Lab, Inc.
 *  All rights reserved.
 *  https://www.gaudiolab.com
 ******************************************************************************/

/**
 * @file just_voice.h
 * @author Gaudio Lab
 * @brief Just Voice SDK Public API header file.
 */

#ifndef JUST_VOICE_H
#define JUST_VOICE_H

#ifdef __cplusplus
#  include <cstdint>
extern "C" {
#else
#  include <stdint.h>
#endif

#if defined(_MSC_VER) && defined(DLL_EXPORT)
#  define SAPI __declspec(dllexport)
#else
#  define SAPI
#endif

/**
 * @brief The error codes for the Just Voice SDK.
 */
enum {
  JV_SUCCESS                           = 0,  /**< Success without any error */
  JV_NOT_CREATED                       = 1,  /**< Failure to use the API when not created using JV_CREATE() */
  JV_NOT_INITIALIZED                   = 2,  /**< Failure to use the API when not initialised using JV_SETUP() */
  JV_ALREADY_CREATED                   = 3,  /**< Failure to use the API when already created using JV_CREATE() */
  JV_ALREADY_INITIALIZED               = 4,  /**< Failure to use the API when already initialised using JV_CREATE() */
  JV_NULL_EXCEPTION                    = 5,  /**< Parameter null pointer error */
  JV_ALLOCATION_FAILED                 = 6,  /**< Failure to allocate memory internally */
  JV_NOT_SUPPORTED_NUM_INPUT_CHANNELS  = 7,  /**< Failure to use the API when not supported number of input channels */
  JV_NOT_SUPPORTED_NUM_OUTPUT_CHANNELS = 8,  /**< Failure to use the API when not supported number of output channels */
  JV_NOT_SUPPORTED_SAMPLE_RATE         = 9,  /**< Failure to use the API when not supported number of sample rate */
  JV_NOT_SUPPORTED_SAMPLES_PER_BLOCK   = 10, /**< Failure to use the API when not supported number of samples per block */
  JV_NOT_SUPPORTED_INTENSITY           = 11, /**< Failure to use the API when not supported number of intensity */
};

/**
 * @brief The configuration structure for the Just Voice SDK.
 */
typedef struct {
  uint32_t numInputChannels;  /**< Configures number of input channels. (Support: 1 ~) */
  uint32_t numOutputChannels; /**< Configures number of output channels. (Support: 1 ~) */
  uint32_t sampleRate;        /**< Configures sample rate. (Support: 8000, 16000, 24000, 32000, 48000, 64000, 96000, 192000) */
  uint32_t samplesPerBlock;   /**< Configures samples per block. 0 for dynamic length. (Support: 0 ~ 32768) */
} just_voice_config_t;

/**
 * @brief The parameters structure for the Just Voice SDK.
 */
typedef struct {
  float noiseReductionIntensity; /**< Configure how strongly to denoise. (Support: 0.0 ~ 1.0) */
} just_voice_params_t;

/**
 * @brief The handle type for the Just Voice SDK.
 */
typedef void* just_voice_handle_t;

/**
 * @brief Returns the version of the Just Voice SDK.
 *
 * @param version Returns a pointer to the version string.
 * @return int32_t Error code.
 */
SAPI int32_t JV_GET_VERSION(char const** version);

/**
 * @brief Creates a new Just Voice handle.
 *
 * @param handle Returns a pointer to the handle.
 * @return int32_t Error code.
 */
SAPI int32_t JV_CREATE(just_voice_handle_t** handle);

/**
 * @brief Destroys a Just Voice handle.
 *
 * @param handle A pointer to the handle to destroy.
 * @return int32_t Error code.
 */
SAPI int32_t JV_DESTROY(just_voice_handle_t** handle);

/**
 * @brief Sets up a Just Voice handle.
 *
 * @param handle A handle to the Just Voice SDK.
 * @param config Configuration for settings that will not be updated.
 * @param params Configuration for settings that can be updated.
 * @return int32_t Error code.
 */
SAPI int32_t JV_SETUP(just_voice_handle_t* handle, just_voice_config_t const* config, just_voice_params_t const* params);

/**
 * @brief Updates a Just Voice handle.
 *
 * @param handle A handle to the Just Voice SDK.
 * @param params Configuration for settings that can be updated.
 * @return int32_t Error code.
 */
SAPI int32_t JV_UPDATE(just_voice_handle_t* handle, just_voice_params_t const* params);

/**
 * @brief Processes audio buffer with Just Voice.
 *
 * @param handle A handle to the Just Voice SDK.
 * @param in Input audio buffer to process.
 * @param out Output audio buffer after rendering.
 * @param length Number of samples in input audio buffer.
 * @return int32_t Error code.
 */
SAPI int32_t JV_PROCESS(just_voice_handle_t* handle, float const* in, float* out, uint32_t length);

/**
 * @brief Returns the latency of the Just Voice SDK handle.
 *
 * @param handle A handle to the Just Voice SDK.
 * @param latency Returns the latency of the handle.
 * @return int32_t Error code.
 */
SAPI int32_t JV_GET_LATENCY(just_voice_handle_t const* handle, float* latency);

#ifdef __cplusplus
}
#endif
#endif  // JUST_VOICE_H
