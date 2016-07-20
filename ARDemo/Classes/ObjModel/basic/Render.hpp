//
//  Render.hpp
//  Application3D
//
//  Created by CharlyZhang on 16/7/15.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#ifndef Render_hpp
#define Render_hpp

#include "../basic/CZMat4.h"
#include "../basic/CZBasic.h"
#include "CZNode.h"
#include <map>

namespace CZ3D {

    
class CZShader;
class Application3D;            ///< for developing
    
// shader type
typedef enum _ShaderType {
    kDirectionalLightShading,		///< directional light shadding mode
    kBlitImage,                      ///< blit image to the renderbuffer
    kBlitColor                      ///< blit color
} ShaderType;

typedef enum RenderMode_ {
    kDirectionalLight
} RenderMode;
   
class RenderResource
{
public:
    RenderResource();
    ~RenderResource();
    GLuint vao;
    GLuint vbo;
};
    
typedef std::map<ShaderType,CZShader*> ShaderMap;
typedef std::map<void*,RenderResource*> GLResourceMap;
typedef std::map<void*,GLuint> TextureMap;
    
class Render
{
public:
    Render();
    ~Render();
    friend class Application3D;
    
    bool init();
    bool blitBackground(CZImage *bgImg, bool clearColor = true);
    bool frame(CZScene &scene,CZNode *pNode, bool clearColor = false);
    bool rawFrame(CZScene &scene,CZNode *pNode, CZMat4 &projMat);
    
    bool setMode(RenderMode mode);
    void setSize(int w, int h);
    void setGLSLDirectory(const char* glslDir);
    
private:
    bool draw(CZNode *pNode, CZMat4 &viewProjMat);
    bool drawObjModel(CZNode *pNode, CZMat4 &viewProjMat);
    bool drawShape(CZNode *pNode, CZMat4 &viewProjMat);
    
    bool prepareBgImage(CZImage *bgImg);
    bool prepareBgVAO();
    RenderResource* prepareObjNodeVAO(CZNode *pNode);
    RenderResource* prepareShapeVAO(CZNode *pNode);
    
    bool enableTexture(CZImage *img);
    
    // shader
    CZShader* getShader(ShaderType type);
    bool loadShaders();
    
    ShaderMap shaders;
    CZMat4 projMat;
    RenderMode mode_;
    CZShader *curShader;
    
    // node
    GLResourceMap resMap;                                      ///< use node memory address to index

    // background image
    RenderResource *pBgImageRes;
    CZImage *ptrBgImage;
    
    // textures
    TextureMap textureMap;
    
    int width,height;
};

}

#endif /* Render_hpp */
