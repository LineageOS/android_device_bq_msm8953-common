/*
 * Copyright (C) 2017 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define LOG_TAG "LightService"

#include <log/log.h>

#include "Light.h"

#include <fstream>

namespace android {
namespace hardware {
namespace light {
namespace V2_0 {
namespace implementation {

#define LEDS            "/sys/class/leds/"

#define LCD_LED         LEDS "lcd-backlight/"
#define RED_LED         LEDS "red/"
#define GREEN_LED       LEDS "green/"
#define BLUE_LED        LEDS "blue/"

#define BLINK           "blink"
#define BRIGHTNESS      "brightness"

/*
 * Write value to path and close file.
 */
static void set(std::string path, std::string value) {
    std::ofstream file(path);
    file << value;
}

static void set(std::string path, int value) {
    set(path, std::to_string(value));
}

static void handleBacklight(const LightState& state) {
    uint32_t brightness = state.color & 0xFF;
    set(LCD_LED BRIGHTNESS, brightness);
}

/*
 * Get blink value as color + pauseHi + pauseLo
 */
static std::string getBlinkValue(uint32_t color, uint32_t pauseHi,
    uint32_t pauseLo) {

    char buffer[40];
    snprintf(buffer, sizeof(buffer), "%d %d %d\n",
        color, pauseHi, pauseLo);
    std::string ret = buffer;
    return ret;
}

static void handleNotification(const LightState& state) {
    uint32_t redBrightness, greenBrightness, blueBrightness, brightness;

    /*
     * Extract brightness from AARRGGBB.
     */
    redBrightness = (state.color >> 16) & 0xFF;
    greenBrightness = (state.color >> 8) & 0xFF;
    blueBrightness = state.color & 0xFF;

    brightness = (state.color >> 24) & 0xFF;

    /*
     * Scale RGB brightness if the Alpha brightness is not 0xFF.
     */
    if (brightness != 0xFF) {
        redBrightness = (redBrightness * brightness) / 0xFF;
        greenBrightness = (greenBrightness * brightness) / 0xFF;
        blueBrightness = (blueBrightness * brightness) / 0xFF;
    }

    /* Disable blinking. */
    set(RED_LED BLINK, 0);
    set(GREEN_LED BLINK, 0);
    set(BLUE_LED BLINK, 0);

    set(RED_LED BRIGHTNESS, 0);
    set(GREEN_LED BRIGHTNESS, 0);
    set(BLUE_LED BRIGHTNESS, 0);

    if (state.flashMode == Flash::TIMED) {
        int32_t pauseHi = state.flashOnMs;
        int32_t pauseLo = state.flashOffMs;
        int32_t blink = 0;

        if (pauseHi > 0 && pauseLo > 0) {
            blink = 1;
        }

        /* Enable blinking if times are higher than 0. */
        if (blink){
            if (redBrightness > 0)
                set(RED_LED BLINK, getBlinkValue(redBrightness, pauseHi, pauseLo));
            if (greenBrightness > 0)
                set(GREEN_LED BLINK, getBlinkValue(greenBrightness, pauseHi, pauseLo));
            if (blueBrightness > 0)
                set(BLUE_LED BLINK, getBlinkValue(blueBrightness, pauseHi, pauseLo));
        }
    } else {
        set(RED_LED BRIGHTNESS, redBrightness);
        set(GREEN_LED BRIGHTNESS, greenBrightness);
        set(BLUE_LED BRIGHTNESS, blueBrightness);
    }
}

static std::map<Type, std::function<void(const LightState&)>> lights = {
    {Type::BACKLIGHT, handleBacklight},
    {Type::BATTERY, handleNotification},
    {Type::NOTIFICATIONS, handleNotification},
    {Type::ATTENTION, handleNotification},
};

Light::Light() {}

Return<Status> Light::setLight(Type type, const LightState& state) {
    auto it = lights.find(type);

    if (it == lights.end()) {
        return Status::LIGHT_NOT_SUPPORTED;
    }

    /*
     * Lock global mutex until light state is updated.
     */
    std::lock_guard<std::mutex> lock(globalLock);

    it->second(state);

    return Status::SUCCESS;
}

Return<void> Light::getSupportedTypes(getSupportedTypes_cb _hidl_cb) {
    std::vector<Type> types;

    for (auto const& light : lights) types.push_back(light.first);

    _hidl_cb(types);

    return Void();
}

}  // namespace implementation
}  // namespace V2_0
}  // namespace light
}  // namespace hardware
}  // namespace android
