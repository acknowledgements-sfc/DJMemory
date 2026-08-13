#include "VDJDeckPoller.h"

#include <chrono>

namespace djmemory {

VDJDeckPoller::VDJDeckPoller(VDJSDKAdapter &adapter, JSONLWriter &writer)
    : adapter_(adapter), writer_(writer) {}

VDJDeckPoller::~VDJDeckPoller() {
    stop();
}

void VDJDeckPoller::start() {
    if (running_.exchange(true)) {
        return;
    }
    worker_ = std::thread(&VDJDeckPoller::run, this);
}

void VDJDeckPoller::stop() {
    if (!running_.exchange(false)) {
        return;
    }
    if (worker_.joinable()) {
        worker_.join();
    }
}

void VDJDeckPoller::run() {
    while (running_.load()) {
        pollOnce();
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
}

void VDJDeckPoller::pollOnce() {
    for (int deck = 1; deck <= kDeckCount; ++deck) {
        const auto snapshot = adapter_.readDeck(deck);
        if (!snapshot.has_value()) {
            continue;
        }

        DeckHistory &history = histories_[static_cast<std::size_t>(deck - 1)];
        const std::string key = trackKey(*snapshot);
        if (!key.empty() && key != history.loadedTrack) {
            writer_.writeTrackLoad(deck, snapshot->artist, snapshot->title);
            history.loadedTrack = key;
        }

        const bool beganPlaying = snapshot->isPlaying && !history.wasPlaying;
        const bool changedWhilePlaying = snapshot->isPlaying && key != history.playedTrack;
        if (!key.empty() && (beganPlaying || changedWhilePlaying)) {
            writer_.writeTrackPlay(
                deck,
                snapshot->artist,
                snapshot->title,
                snapshot->elapsedSeconds
            );
            history.playedTrack = key;
        }
        history.wasPlaying = snapshot->isPlaying;
    }
}

std::string VDJDeckPoller::trackKey(const DeckSnapshot &snapshot) {
    if (snapshot.artist.empty() && snapshot.title.empty()) {
        return {};
    }
    return snapshot.artist + '\x1f' + snapshot.title;
}

} // namespace djmemory
