#include "JSONLWriter.h"

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <iomanip>
#include <random>
#include <sstream>
#include <unistd.h>

namespace djmemory {
namespace {

std::string utcString(std::time_t value, const char *format) {
    std::tm utc {};
    gmtime_r(&value, &utc);
    char buffer[32] = {};
    std::strftime(buffer, sizeof(buffer), format, &utc);
    return buffer;
}

} // namespace

JSONLWriter::JSONLWriter() : sessionID_(makeSessionID()) {}

JSONLWriter::~JSONLWriter() {
    endSession();
}

bool JSONLWriter::startSession() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (sessionOpen_) {
        return true;
    }

    const std::string folder = dropFolderPath();
    std::error_code error;
    std::filesystem::create_directories(folder, error);
    if (error) {
        return false;
    }

    const std::time_t now = std::time(nullptr);
    outputPath_ = folder + "/set-" + utcString(now, "%Y-%m-%d") + "-" + sessionID_ + ".jsonl";
    stream_.open(outputPath_, std::ios::out | std::ios::app);
    if (!stream_.is_open()) {
        return false;
    }

    sessionOpen_ = true;
    stream_ << baseEvent("session_start")
            << ",\"plugin\":\"0.1.0\",\"app\":\"virtualdj\"}\n";
    stream_.flush();
    return stream_.good();
}

void JSONLWriter::writeTrackLoad(
    int deck,
    const std::string &artist,
    const std::string &title
) {
    std::ostringstream line;
    line << baseEvent("track_load")
         << ",\"deck\":" << deck
         << ",\"artist\":\"" << escapeJSON(artist)
         << "\",\"title\":\"" << escapeJSON(title) << "\"}";
    appendLine(line.str());
}

void JSONLWriter::writeTrackPlay(
    int deck,
    const std::string &artist,
    const std::string &title,
    double elapsedSeconds
) {
    std::ostringstream line;
    line << baseEvent("track_play")
         << ",\"deck\":" << deck
         << ",\"artist\":\"" << escapeJSON(artist)
         << "\",\"title\":\"" << escapeJSON(title) << "\"";
    if (elapsedSeconds >= 0.0) {
        line << ",\"elapsed\":" << std::fixed << std::setprecision(3) << elapsedSeconds;
    }
    line << "}";
    appendLine(line.str());
}

void JSONLWriter::endSession() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!sessionOpen_) {
        return;
    }

    stream_ << baseEvent("session_end") << "}\n";
    stream_.flush();
    stream_.close();
    sessionOpen_ = false;
}

void JSONLWriter::appendLine(const std::string &payload) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!sessionOpen_) {
        return;
    }
    stream_ << payload << '\n';
    stream_.flush();
}

std::string JSONLWriter::baseEvent(const char *type) {
    std::ostringstream line;
    line << "{\"v\":1,\"type\":\"" << type
         << "\",\"ts\":\"" << nextTimestamp()
         << "\",\"session\":\"" << sessionID_ << "\"";
    return line.str();
}

std::string JSONLWriter::nextTimestamp() {
    const std::time_t now = std::time(nullptr);
    lastTimestamp_ = std::max(lastTimestamp_, now);
    return utcString(lastTimestamp_, "%Y-%m-%dT%H:%M:%SZ");
}

std::string JSONLWriter::escapeJSON(const std::string &value) {
    std::ostringstream escaped;
    for (const unsigned char character : value) {
        switch (character) {
        case '\"': escaped << "\\\""; break;
        case '\\': escaped << "\\\\"; break;
        case '\b': escaped << "\\b"; break;
        case '\f': escaped << "\\f"; break;
        case '\n': escaped << "\\n"; break;
        case '\r': escaped << "\\r"; break;
        case '\t': escaped << "\\t"; break;
        default:
            if (character < 0x20) {
                escaped << "\\u" << std::hex << std::setw(4) << std::setfill('0')
                        << static_cast<int>(character) << std::dec;
            } else {
                escaped << character;
            }
        }
    }
    return escaped.str();
}

std::string JSONLWriter::makeSessionID() {
    const auto now = std::chrono::system_clock::now().time_since_epoch().count();
    std::random_device random;
    std::ostringstream value;
    value << std::hex << now << '-' << getpid() << '-' << random();
    return value.str();
}

std::string JSONLWriter::dropFolderPath() {
    const char *homeDirectory = std::getenv("HOME");
    if (homeDirectory == nullptr || homeDirectory[0] == '\0') {
        return {};
    }
    return std::string(homeDirectory) + "/Documents/VirtualDJ/DJMemoryDrop";
}

} // namespace djmemory
