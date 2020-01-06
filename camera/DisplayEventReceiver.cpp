#include <stdint.h>
#include <gui/ISurfaceComposer.h>

namespace android {
    extern "C" void _ZN7android20DisplayEventReceiverC1ENS_16ISurfaceComposer11VsyncSourceENS1_13ConfigChangedE(void* vsyncSource, ISurfaceComposer::ConfigChanged configChanged);

    extern "C" void _ZN7android20DisplayEventReceiverC1ENS_16ISurfaceComposer11VsyncSourceE(void *vsyncSource) {
                    _ZN7android20DisplayEventReceiverC1ENS_16ISurfaceComposer11VsyncSourceENS1_13ConfigChangedE(vsyncSource, ISurfaceComposer::eConfigChangedSuppress);
    }
}
