#include <stdint.h>
#include <gui/ISurfaceComposer.h>

namespace android {
    extern "C" void _ZN7android20DisplayEventReceiverC2ENS_16ISurfaceComposer11VsyncSourceENS_3ftl5FlagsINS1_17EventRegistrationEEE(void* vsyncSource, ISurfaceComposer::EventRegistrationFlags eventRegistration);

    extern "C" void _ZN7android20DisplayEventReceiverC1ENS_16ISurfaceComposer11VsyncSourceE(void *vsyncSource) {
                    ISurfaceComposer::EventRegistrationFlags eventRegistration = {};
                    _ZN7android20DisplayEventReceiverC2ENS_16ISurfaceComposer11VsyncSourceENS_3ftl5FlagsINS1_17EventRegistrationEEE(vsyncSource, eventRegistration);
    }
}
