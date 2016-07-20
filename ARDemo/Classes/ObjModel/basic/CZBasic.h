
#ifndef _CZBASIC_H_
#define _CZBASIC_H_

#include "CZVector.h"

namespace CZ3D {

// 3D Point
typedef CZVector3D<float> CZPoint3D;

// Color
typedef struct _CZColor {
	float r,g,b,a;
	_CZColor(float r_=0.0,float g_=0.0,float b_=0.0,float a_=0.0){r=r_; g=g_; b=b_; a=a_;}
} CZColor;

// Light
typedef struct _CZLight {
	CZPoint3D position;
	CZPoint3D intensity;
} CZLight;

typedef struct _CZAmbientLight {
	CZPoint3D intensity;
} CZAmbientLight;

typedef struct _CZDirectionalLight {
	CZPoint3D direction;
	CZPoint3D intensity;
} CZDirectionalLight;

class VertexData
{
public:
    CZVector3D<float> position;
    CZVector3D<float> normal;
    CZVector2D<float> texcoord;
};

// Scene
typedef struct _CZScene {
	CZColor	bgColor;                        //< background color
	CZColor mColor;							//< model color
	CZLight	light;							//< point light
	CZAmbientLight ambientLight;			//< ambient light
	CZDirectionalLight directionalLight;	//< diretional light
	CZPoint3D eyePosition;					//< eye position
    float     cameraFov;                    //< camera fov
    float     cameraNearPlane;
    float     camearFarPlane;
} CZScene;


// Image
class CZImage
{
public:
    typedef enum _ColorSpace {
		RGB,
        RGBA,
        GRAY
    } ColorSpace;
    
    // \note
    // rgba
    CZImage(int w = 0, int h = 0, ColorSpace c = RGBA):width(w), height(h), colorSpace(c)
    {
        if (w != 0 && h != 0)
        {
            int n;
            switch (colorSpace) {
				case RGB:
					n = 3;
                case RGBA:
                    n = 4;
                    break;
                case GRAY:
                    n = 1;
                    break;
                default:
                    break;
            }
            data = new unsigned char [w*h*n];
        }
        else                  data = nullptr;
    }
    ~CZImage() {if(data) delete [] data;}

    int width,height;
    unsigned char *data;
    ColorSpace colorSpace;
};
}

#endif