#pragma once

#include <optional>
#include <string>

#include <vdjPlugin8.h>

namespace djmemory {

struct DeckSnapshot {
    std::string artist;
    std::string title;
    double elapsedSeconds = -1.0;
    bool isPlaying = false;
};

class VDJSDKAdapter {
public:
    explicit VDJSDKAdapter(IVdjPlugin8 &plugin) : plugin_(plugin) {}

    std::optional<DeckSnapshot> readDeck(int deck);

private:
    std::optional<std::string> getString(const std::string &query);
    std::optional<double> getNumber(const std::string &query);
    static std::string deckQuery(int deck, const char *verb);

    IVdjPlugin8 &plugin_;
};

} // namespace djmemory
