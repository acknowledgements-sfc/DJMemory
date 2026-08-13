#include "JSONLWriter.h"
#include "VDJDeckPoller.h"
#include "VDJSDKAdapter.h"

#include <cstring>
#include <memory>

namespace {

bool guidEquals(const GUID &left, const GUID &right) {
    return std::memcmp(&left, &right, sizeof(GUID)) == 0;
}

class DJMemoryVirtualDJPlugin final : public IVdjPluginStartStop8 {
public:
    ~DJMemoryVirtualDJPlugin() override {
        stopCapture();
    }

    HRESULT VDJ_API OnLoad() override {
        adapter_ = std::make_unique<djmemory::VDJSDKAdapter>(*this);
        return startCapture();
    }

    HRESULT VDJ_API OnGetPluginInfo(TVdjPluginInfo8 *info) override {
        if (info == nullptr) {
            return static_cast<HRESULT>(-1);
        }
        info->PluginName = "DJMemory Track Events";
        info->Author = "DJMemory";
        info->Description = "Writes VirtualDJ track events for DJMemory";
        info->Version = "0.1.0";
        info->Bitmap = nullptr;
        info->Flags = 0;
        return S_OK;
    }

    HRESULT VDJ_API OnStart() override {
        return startCapture();
    }

    HRESULT VDJ_API OnStop() override {
        stopCapture();
        return S_OK;
    }

private:
    HRESULT startCapture() {
        if (poller_) {
            return S_OK;
        }

        if (!adapter_) {
            adapter_ = std::make_unique<djmemory::VDJSDKAdapter>(*this);
        }

        writer_ = std::make_unique<djmemory::JSONLWriter>();
        if (!writer_->startSession()) {
            writer_.reset();
            return static_cast<HRESULT>(-1);
        }

        poller_ = std::make_unique<djmemory::VDJDeckPoller>(*adapter_, *writer_);
        poller_->start();
        return S_OK;
    }

    void stopCapture() {
        if (poller_) {
            poller_->stop();
            poller_.reset();
        }
        if (writer_) {
            writer_->endSession();
            writer_.reset();
        }
    }

    std::unique_ptr<djmemory::VDJSDKAdapter> adapter_;
    std::unique_ptr<djmemory::JSONLWriter> writer_;
    std::unique_ptr<djmemory::VDJDeckPoller> poller_;
};

} // namespace

extern "C" VDJ_EXPORT HRESULT VDJ_API DllGetClassObject(
    const GUID &classID,
    const GUID &interfaceID,
    void **object
) {
    if (object == nullptr) {
        return CLASS_E_CLASSNOTAVAILABLE;
    }
    *object = nullptr;

    const bool supportedClass = guidEquals(classID, CLSID_VdjPlugin8);
    const bool supportedInterface = guidEquals(interfaceID, IID_IVdjPluginStartStop8)
        || guidEquals(interfaceID, IID_IVdjPluginBasic8);
    if (!supportedClass || !supportedInterface) {
        return CLASS_E_CLASSNOTAVAILABLE;
    }

    *object = new DJMemoryVirtualDJPlugin();
    return S_OK;
}
