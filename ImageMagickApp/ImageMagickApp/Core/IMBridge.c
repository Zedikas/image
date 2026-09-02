#include "IMBridge.h"
#include <stdlib.h>
#include <string.h>

#include <MagickWand/MagickWand.h>

static char last_error[1024];

static void set_error(MagickWand *wand) {
    ExceptionType severity = UndefinedException;
    char *description = MagickGetException(wand, &severity);
    if (description) {
        strncpy(last_error, description, sizeof(last_error) - 1);
        last_error[sizeof(last_error) - 1] = '\0';
        MagickRelinquishMemory(description);
    } else {
        strncpy(last_error, "ImageMagick operation failed.", sizeof(last_error) - 1);
    }
}

const char *IMBridgeLastError(void) {
    return last_error;
}

const char *IMBridgeVersion(void) {
    static char version[128];
    size_t length = 0;
    const char *v = MagickGetVersion(&length);
    if (!v) return "unknown";
    strncpy(version, v, sizeof(version) - 1);
    version[sizeof(version) - 1] = '\0';
    return version;
}

IMProcessedImage IMBridgeResizeAndSharpen(
    const unsigned char *rgba,
    size_t width,
    size_t height,
    size_t target_width
) {
    IMProcessedImage result = {0};

    if (!rgba || width == 0 || height == 0 || target_width == 0) {
        strncpy(last_error, "Invalid image dimensions or pixel buffer.", sizeof(last_error) - 1);
        return result;
    }

    MagickWandGenesis();

    MagickWand *wand = NewMagickWand();
    if (!wand) {
        strncpy(last_error, "Could not create MagickWand.", sizeof(last_error) - 1);
        return result;
    }

    if (MagickConstituteImage(wand, width, height, "RGBA", CharPixel, rgba) == MagickFalse) {
        set_error(wand);
        DestroyMagickWand(wand);
        return result;
    }

    size_t target_height = (height * target_width + width / 2) / width;

    if (MagickResizeImage(wand, target_width, target_height, LanczosFilter) == MagickFalse) {
        set_error(wand);
        DestroyMagickWand(wand);
        return result;
    }

    if (MagickSharpenImage(wand, 0.0, 0.8) == MagickFalse) {
        set_error(wand);
        DestroyMagickWand(wand);
        return result;
    }

    if (MagickSetImageFormat(wand, "RGBA") == MagickFalse) {
        set_error(wand);
        DestroyMagickWand(wand);
        return result;
    }

    size_t blob_length = 0;
    unsigned char *blob = MagickGetImageBlob(wand, &blob_length);
    if (!blob || blob_length == 0) {
        set_error(wand);
        DestroyMagickWand(wand);
        return result;
    }

    result.bytes = malloc(blob_length);
    if (!result.bytes) {
        strncpy(last_error, "Out of memory.", sizeof(last_error) - 1);
        MagickRelinquishMemory(blob);
        DestroyMagickWand(wand);
        return (IMProcessedImage){0};
    }

    memcpy(result.bytes, blob, blob_length);
    result.length = blob_length;
    result.width = MagickGetImageWidth(wand);
    result.height = MagickGetImageHeight(wand);

    MagickRelinquishMemory(blob);
    DestroyMagickWand(wand);
    return result;
}

void IMBridgeFreeImage(IMProcessedImage image) {
    free(image.bytes);
}
