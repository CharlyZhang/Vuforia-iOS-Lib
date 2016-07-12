#include <string>
#include "CZBasic.h"
#include "CZDefine.h"

#if defined(_WIN32)
#   include "FreeImage.h"
#elif defined(__APPLE__)
#   import <Foundation/Foundation.h>
#   import <UIKit/UIKit.h>
#   import "UIImage+Resize.h"
#else
#include <android/bitmap.h>
extern JNIEnv *jniEnv;

extern char* GetImageClass;
extern char* GetImageMethod;

extern char* ModelLoadCallerClass;
extern char* ModelLoadCallerMethod;

#endif

using namespace std;

#if defined(__ANDROID__)


jstring charToJstring(JNIEnv* env, const char* pat)
{
    return env->NewStringUTF(pat);
    //    jclass     strClass = env->FindClass("java/lang/String");
    //    jmethodID  ctorID   = env->GetMethodID(strClass, "", "([BLjava/lang/String;)V");
    //    jbyteArray bytes    = env->NewByteArray(strlen(pat));
    //    env->SetByteArrayRegion(bytes, 0, strlen(pat), (jbyte*)pat);
    //    jstring    encoding = env->NewStringUTF("UTF-8");
    //    return (jstring)env->NewObject(strClass, ctorID, bytes, encoding);
}

#endif

void CZCheckGLError_(const char *file, int line)
{
    int    retCode = 0;
    GLenum glErr = glGetError();
    
    while (glErr != GL_NO_ERROR)
    {
        
#if defined USE_OPENGL
        const GLubyte* sError = gluErrorString(glErr);
        
        if (sError)
            printf("GL Error #%d (%s) in File %s at line: %d\n",glErr,gluErrorString(glErr),file,line);
        else
            printf("GL Error #%d (no message available) in File %s at line: %d\n",glErr,file,line);
        
#elif defined USE_OPENGL_ES
        switch (glErr) {
            case GL_INVALID_ENUM:
                printf("(%s): %d - GL Error: Enum argument is out of range\n",file,line);
                break;
            case GL_INVALID_VALUE:
                printf("(%s): %d - GL Error: Numeric value is out of range\n",file,line);
                break;
            case GL_INVALID_OPERATION:
                printf("(%s): %d - GL Error: Operation illegal in current state\n",file,line);
                break;
                //        case GL_STACK_OVERFLOW:
                //            NSLog(@"GL Error: Command would cause a stack overflow");
                //            break;
                //        case GL_STACK_UNDERFLOW:
                //            NSLog(@"GL Error: Command would cause a stack underflow");
                //            break;
            case GL_OUT_OF_MEMORY:
                printf("(%s): %d - GL Error: Not enough memory to execute command\n",file,line);
                break;
            case GL_NO_ERROR:
                if (1) {
                    printf("No GL Error\n");
                }
                break;
            default:
                printf("(%s): %d - Unknown GL Error\n",file,line);
                break;
        }
#endif
        
        retCode = 1;
        glErr = glGetError();
    }
    //return retCode;
};

CZImage *CZLoadTexture(const string &filename)
{
# ifdef _WIN32
    //image format
    FREE_IMAGE_FORMAT fif = FIF_UNKNOWN;
    //pointer to the image, once loaded
    FIBITMAP *dib(0);
    //pointer to the image data
    BYTE* bits(0);
    //image width and height
    unsigned int width(0), height(0);
    
    //check the file signature and deduce its format
    fif = FreeImage_GetFileType(filename.c_str(), 0);
    //if still unknown, try to guess the file format from the file extension
    if (fif == FIF_UNKNOWN)
        fif = FreeImage_GetFIFFromFilename(filename.c_str());
    //if still unkown, return failure
    if (fif == FIF_UNKNOWN)
        return false;
    
    //check that the plugin has reading capabilities and load the file
    if (FreeImage_FIFSupportsReading(fif))
        dib = FreeImage_Load(fif, filename.c_str());
    //if the image failed to load, return failure
    if (!dib)
        return false;
    
    //retrieve the image data
    bits = FreeImage_GetBits(dib);
    //get the image width and height
    width = FreeImage_GetWidth(dib);
    height = FreeImage_GetHeight(dib);
    //if this somehow one of these failed (they shouldn't), return failure
    if ((bits == 0) || (width == 0) || (height == 0))
        return false;
    
    unsigned int bpp = FreeImage_GetBPP(dib);
    LOG_DEBUG("bpp is %u\n",bpp);
    FREE_IMAGE_TYPE type = FreeImage_GetImageType(dib);
    FREE_IMAGE_COLOR_TYPE colorType = FreeImage_GetColorType(dib);
    
    // TO DO: inverse pixel data sequence manually
    GLint components;
    CZImage::ColorSpace czColorSpace;
    switch (colorType)
    {
        case FIC_RGB:
            components = 3;
            czColorSpace = CZImage::RGB;
            break;
        case FIC_RGBALPHA:
            components = 4;
            czColorSpace = CZImage::RGBA;
            break;
        default:
            components = 3;
            czColorSpace = CZImage::RGB;
            LOG_WARN("the color type has not been considered\n");
            break;
    }
    
    CZImage *retImage = new CZImage((int)width,(int)height,czColorSpace);
    //memcpy(retImage->data,bits,width*height*components*sizeof(unsigned char));
    
    unsigned char *dst = retImage->data;
    for (unsigned int i=0; i<height*width; i++)
    {
        dst[i*components+0] = bits[i*components+2];
        dst[i*components+1] = bits[i*components+1];
        dst[i*components+2] = bits[i*components+0];
    }
    
    
    //Free FreeImage's copy of the data
    FreeImage_Unload(dib);
    
    return retImage;
    // TO DO: to load bmp with bpp=32
    
#elif defined(__APPLE__)
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithCString:filename.c_str() encoding:NSUTF8StringEncoding]];
    
    float maxTexSize;
    glGetFloatv(GL_MAX_TEXTURE_SIZE, &maxTexSize);
    CGSize imageSize = image.size;
    if (imageSize.width > imageSize.height) {
        if (imageSize.width > maxTexSize) {
            imageSize.height = (imageSize.height / imageSize.width) * maxTexSize;
            imageSize.width = maxTexSize;
            
            LOG_INFO("image(%f,%f) is resized to (%f,%f)\n",image.size.width,image.size.height,imageSize.width, imageSize.height);
            image = [image resizedImage:imageSize interpolationQuality:kCGInterpolationHigh];
        }
    } else {
        if (imageSize.height > maxTexSize) {
            imageSize.width = (imageSize.width / imageSize.height) * maxTexSize;
            imageSize.height = maxTexSize;
            
            LOG_INFO("image(%f,%f) is resized to (%f,%f)\n",image.size.width,image.size.height,imageSize.width, imageSize.height);
            image = [image resizedImage:imageSize interpolationQuality:kCGInterpolationHigh];
        }
    }
    
    if (!image) {
        LOG_ERROR("image is nil\n");
        return nullptr;
    }
    
    CGImageRef img = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(img);
    //    size_t componentNum = CGColorSpaceGetNumberOfComponents(colorSpace);
    CGColorSpaceModel spaceColorModel = CGColorSpaceGetModel(colorSpace);
    int componentNum;
    CZImage::ColorSpace czColorSpace;
    switch (spaceColorModel) {
        case kCGColorSpaceModelMonochrome:
            componentNum = 1;
            czColorSpace = CZImage::GRAY;
            break;
        case kCGColorSpaceModelRGB:
            componentNum = 4;
            czColorSpace = CZImage::RGBA;
            break;
        default:
            break;
    }
    
    // data provider
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    // provider’s data.
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    
    const UInt8 *data = CFDataGetBytePtr(inBitmapData);
    
    //size，data
    size_t width= CGImageGetWidth(img);
    size_t height = CGImageGetHeight(img);
    
    CZImage *retImage = new CZImage((int)width,(int)height,czColorSpace);
    unsigned char *src = (UInt8*)&data[(height-1)*width*componentNum];
    UInt8 *dst = retImage->data;
    for (int i=0; i<height; i++)
    {
        memcpy(dst,src,width*componentNum);
        dst += (width*componentNum);
        src -= (width*componentNum);
    }
    
    CFRelease(inBitmapData);
    
    return retImage;
#elif defined(__ANDROID__)
    
    
    if(GetImageClass == nullptr || GetImageMethod == nullptr) return nullptr;
    
    jclass cls = jniEnv->FindClass(GetImageClass);
    jmethodID mid = jniEnv->GetStaticMethodID(cls, GetImageMethod, "(Ljava/lang/String;)Landroid/graphics/Bitmap;");
    
    jstring path = charToJstring(jniEnv,filename.c_str());
    jobject bitmap = jniEnv->CallStaticObjectMethod(cls,mid,path);
    
    void *addr;
    AndroidBitmapInfo info;
    int errorCode;
    
    if ((errorCode = AndroidBitmap_lockPixels(jniEnv, bitmap, &addr)) != 0) {
        LOG_INFO("error %d", errorCode);
    }
    
    if ((errorCode = AndroidBitmap_getInfo(jniEnv, bitmap, &info)) != 0) {
        LOG_INFO("error %d", errorCode);
    }
    
    LOG_INFO("bitmap info: %d wide, %d tall, %d ints per pixel", info.width, info.height, info.format);
    
    if (info.width <= 0 || info.height <= 0 ||
        (info.format != ANDROID_BITMAP_FORMAT_A_8 && info.format != ANDROID_BITMAP_FORMAT_RGBA_8888)) {
        LOG_ERROR("invalid bitmap\n");
        jniEnv->ThrowNew(jniEnv->FindClass("java/io/IOException"), "invalid bitmap");
        return nullptr;
    }
    
    int componentNum;
    CZImage::ColorSpace czColorSpace;
    switch (info.format) {
        case ANDROID_BITMAP_FORMAT_A_8:
            componentNum = 1;
            czColorSpace = CZImage::GRAY;
            break;
        case ANDROID_BITMAP_FORMAT_RGBA_8888:
            componentNum = 4;
            czColorSpace = CZImage::RGBA;
            break;
        default:
            break;
    }
    
    CZImage *retImage = new CZImage((int)info.width,(int)info.height,czColorSpace);
    long size = info.width * info.height * componentNum;
    memcpy(retImage->data, addr, size * sizeof(unsigned char));
    
    if ((errorCode = AndroidBitmap_unlockPixels(jniEnv, bitmap)) != 0) {
        LOG_INFO("error %d", errorCode);
    }
    
    return retImage;
    
#endif
}

void modelLoadingDone()
{
#if defined(__ANDROID__)
    
    if(ModelLoadCallerClass == nullptr || ModelLoadCallerMethod == nullptr) return;
    
    jclass cls = jniEnv->FindClass(ModelLoadCallerClass);
    jmethodID mid = jniEnv->GetStaticMethodID(cls, ModelLoadCallerMethod, "()V");
    
    jniEnv->CallStaticVoidMethod(cls,mid);
    
#endif
}