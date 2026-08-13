#pragma once

#include <ctime>
#include <fstream>
#include <mutex>
#include <string>

namespace djmemory {

class JSONLWriter {
public:
    JSONLWriter();
    ~JSONLWriter();

    bool startSession();
    void writeTrackLoad(int deck, const std::string &artist, const std::string &title);
    void writeTrackPlay(
        int deck,
        const std::string &artist,
        const std::string &title,
        double elapsedSeconds
    );
    void endSession();

    const std::string &outputPath() const { return outputPath_; }

private:
    void appendLine(const std::string &payload);
    std::string baseEvent(const char *type);
    std::string nextTimestamp();

    static std::string escapeJSON(const std::string &value);
    static std::string makeSessionID();
    static std::string dropFolderPath();

    std::mutex mutex_;
    std::ofstream stream_;
    std::string sessionID_;
    std::string outputPath_;
    std::time_t lastTimestamp_ = 0;
    bool sessionOpen_ = false;
};

} // namespace djmemory
