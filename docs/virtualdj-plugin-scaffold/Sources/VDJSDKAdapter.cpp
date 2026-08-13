#include "VDJSDKAdapter.h"

#include <array>
#include <cstdio>

namespace djmemory {
namespace {

// These VDJScript getter strings are intentionally centralized. The C++ API
// calls are SDK-confirmed; the strings remain live-validation items for M14.
constexpr const char *kArtistQuery = "get_artist";
constexpr const char *kTitleQuery = "get_title";
constexpr const char *kPlayingQuery = "play";
constexpr const char *kElapsedQuery = "get_time elapsed";

} // namespace

std::optional<DeckSnapshot> VDJSDKAdapter::readDeck(int deck) {
    const auto artist = getString(deckQuery(deck, kArtistQuery));
    const auto title = getString(deckQuery(deck, kTitleQuery));
    const auto playing = getNumber(deckQuery(deck, kPlayingQuery));
    if (!artist.has_value() || !title.has_value() || !playing.has_value()) {
        return std::nullopt;
    }

    DeckSnapshot snapshot;
    snapshot.artist = *artist;
    snapshot.title = *title;
    snapshot.isPlaying = *playing > 0.5;
    if (const auto elapsed = getNumber(deckQuery(deck, kElapsedQuery))) {
        snapshot.elapsedSeconds = *elapsed;
    }
    return snapshot;
}

std::optional<std::string> VDJSDKAdapter::getString(const std::string &query) {
    std::array<char, 2048> buffer {};
    if (plugin_.GetStringInfo(query.c_str(), buffer.data(), static_cast<int>(buffer.size())) != S_OK) {
        return std::nullopt;
    }
    return std::string(buffer.data());
}

std::optional<double> VDJSDKAdapter::getNumber(const std::string &query) {
    double value = 0.0;
    if (plugin_.GetInfo(query.c_str(), &value) != S_OK) {
        return std::nullopt;
    }
    return value;
}

std::string VDJSDKAdapter::deckQuery(int deck, const char *verb) {
    std::array<char, 128> query {};
    std::snprintf(query.data(), query.size(), "deck %d %s", deck, verb);
    return std::string(query.data());
}

} // namespace djmemory
