#include "CZMaterial.h"
#include "CZDefine.h"

using namespace std;

namespace CZ3D {
    
CZMaterial::CZMaterial()
{
    Ns = 10;						//	shininess
    Ka[0] = Ka[1] = Ka[2] = 0.2f;	//	ambient color
    Ka[3] = 0;
    Kd[0] = Kd[1] = Kd[2] = 0.8f;	// diffuse color
    Kd[3] = 0;
    Ks[0] = Ks[1] = Ks[2] = Ks[3] = 0;	//	specular color
    Ke[0] = Ke[1] = Ke[2] = Ke[3] = 0;	//	specular color
    
    texImage = NULL;
}

CZMaterial::~CZMaterial()
{
    if (texImage)   delete texImage;
}
    
}

