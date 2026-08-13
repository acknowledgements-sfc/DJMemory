#pragma once

#include "JSONLWriter.h"
#include "VDJSDKAdapter.h"

#include <array>
#include <atomic>
#include <string>
#include <thread>

namespace djmemory {

class VDJDeckPoller {
public:
    VDJDeckPoller(VDJSDKAdapter &adapter, JSONLWriter &writer);
    ~VDJDeckPoller();

    void start();
    void stop();

private:
    struct DeckHistory {
        std::string loadedTrack;
        std::string playedTrack;
        bool wasPlaying = false;
    };

    void run();
    void pollOnce();
    static std::string trackKey(const DeckSnapshot &snapshot);

    static constexpr int kDeckCount = 4;

    VDJSDKAdapter &adapter_;
    JSONLWriter &writer_;
    std::array<DeckHistory, kDeckCount> histories_ {};
    std::atomic<bool> running_ {false};
    std::thread worker_;
};

} // namespace djmemory
