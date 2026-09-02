#ifndef IMBridge_h
#define IMBridge_h

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    unsigned char *bytes;
    size_t length;
    size_t width;
    size_t height;
} IMProcessedImage;

const char *IMBridgeVersion(void);
IMProcessedImage IMBridgeResizeAndSharpen(
    const unsigned char *rgba,
    size_t width,
    size_t height,
    size_t target_width
);
void IMBridgeFreeImage(IMProcessedImage image);
const char *IMBridgeLastError(void);

#ifdef __cplusplus
}
#endif

#endif
