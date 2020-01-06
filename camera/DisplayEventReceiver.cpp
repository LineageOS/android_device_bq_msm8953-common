#include <stdint.h>
#include <gui/ISurfaceComposer.h>

namespace android {
    extern "C" void _ZN7android20DisplayEventReceiverC1ENS_16ISurfaceComposer11VsyncSourceENS1_13ConfigChangedE(ISurfaceComposer::VsyncSource vsyncSource, ISurfaceComposer::ConfigChanged configChanged);

    extern "C" void _ZN7android20DisplayEventReceiverC1ENS_16ISurfaceComposer11VsyncSourceE(ISurfaceComposer::VsyncSource vsyncSource) {
                    _ZN7android20DisplayEventReceiverC1ENS_16ISurfaceComposer11VsyncSourceENS1_13ConfigChangedE(vsyncSource, ISurfaceComposer::eConfigChangedSuppress);
    }
}
