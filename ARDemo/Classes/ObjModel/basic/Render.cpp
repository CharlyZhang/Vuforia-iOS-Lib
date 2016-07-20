//
//  Render.cpp
//  Application3D
//
//  Created by CharlyZhang on 16/7/15.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#include "Render.hpp"
#include "CZDefine.h"
#include "../basic/CZShader.h"
#include "../objModel/CZObjModel.h"
#include "../shape/CZCube.hpp"
#include <vector>

#define DEFAULT_RENDER_SIZE 500					///< default render buffer size

using namespace std;

namespace CZ3D {
    
    RenderResource::RenderResource()
    {
        vao = -1;
        vbo = -1;
    }
    
    RenderResource::~RenderResource()
    {
        if(vao != -1) GL_DEL_VERTEXARRAY(1, &vao);
        if(vbo != -1) glDeleteBuffers(1, &vbo);
    }
    
    Render::Render()
    {
        width = height = DEFAULT_RENDER_SIZE;
        mode_ = kDirectionalLight;
        curShader = nullptr;
        
        // texture
        textureMap.clear();
        
        pBgImageRes = nullptr;
        ptrBgImage = nullptr;
    }
    
    Render::~Render()
    {
        for (ShaderMap::iterator itr = shaders.begin(); itr != shaders.end(); itr++)
        {
            delete itr->second;
        }
        shaders.clear();
        
        // texture
        for (TextureMap::iterator itr = textureMap.begin();  itr != textureMap.end(); itr++)
            glDeleteTextures(1, &itr->second);
        textureMap.clear();
        
        // node
        for(GLResourceMap::iterator itr = resMap.begin(); itr != resMap.end(); itr++)
            delete itr->second;
        resMap.clear();
        
        if(pBgImageRes) delete pBgImageRes;
    }
    
    bool Render::init()
    {
# ifdef _WIN32
        /// OpenGL initialization
        glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
        glShadeModel(GL_SMOOTH);					// smooth shade model
        
        glClearDepth(1.0f);							// set clear depth
        glEnable(GL_DEPTH_TEST);
        
        glEnable(GL_NORMALIZE);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
        
        //texture
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        //glEnable(GL_TEXTURE_2D);
# else
        
        glClearDepthf(1.0f);									// set clear depth
        glEnable(GL_DEPTH_TEST);
# endif
        
        //    glCullFace(GL_BACK);                            ///< cull back face
        //    glEnable(GL_CULL_FACE);
        
        CZCheckGLError();
        
#if	defined(__APPLE__)	|| defined(_WIN32)
        loadShaders();
#endif
        return true;
    }
    
    bool Render::blitBackground(CZImage *bgImg, bool clearColor /* = true */)
    {
        if(bgImg == nullptr)
        {
            LOG_ERROR("bgImg is nullptr!\n");
            return false;
        }
        
        CZShader *pShader = getShader(kBlitImage);
        
        if (pShader == NULL)
        {
            LOG_ERROR("there's no shader for blitting background image\n");
            return false;
        }
        
        if(prepareBgImage(bgImg) == false) return false;
        if(prepareBgVAO() == false) return false;
        
        // draw Rect
        glClear(GL_DEPTH_BUFFER_BIT);
        
        if(clearColor)
            glClear(GL_COLOR_BUFFER_BIT);
        
        CZMat4 mvpMat;
        mvpMat.SetOrtho(0,width,0,height,-1.0f,1.0f);
        
        pShader->begin();
        glUniformMatrix4fv(pShader->getUniformLocation("mvpMat"),1,GL_FALSE,mvpMat);
        glUniform1i(pShader->getUniformLocation("texture"), (GLuint) 0);
        glUniform1f(pShader->getUniformLocation("opacity"), 1.0f); // fully opaque
        
        enableTexture(bgImg);
        
        // clear the buffer to get a transparent background
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT );
        
        // set up premultiplied normal blend
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        GL_BIND_VERTEXARRAY(pBgImageRes->vao);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        GL_BIND_VERTEXARRAY(0);
        
        pShader->end();
        
        CZCheckGLError();
        
        return true;
    }
    
    bool Render::frame(CZScene &scene, CZNode *pRootNode, bool clearColor /* = false */)
    {
        
# ifdef _WIN32
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        gluLookAt(scene.eyePosition.x,scene.eyePosition.y,scene.eyePosition.z, 0,0,0,0,1,0);
# endif
        
        glClearColor(scene.bgColor.r, scene.bgColor.g, scene.bgColor.b, scene.bgColor.a);
        
        glClear(GL_DEPTH_BUFFER_BIT);
        if(clearColor)  glClear(GL_COLOR_BUFFER_BIT);
        
        projMat.SetPerspective(scene.cameraFov,(GLfloat)width/(GLfloat)height, scene.cameraNearPlane, scene.camearFarPlane);
        CZMat4 viewMat,viewProjMat;
        
        viewMat.SetLookAt(scene.eyePosition.x, scene.eyePosition.y, scene.eyePosition.z, 0, 0, 0, 0, 1, 0);
        viewProjMat = projMat * viewMat;
        
        curShader = getShader(kDirectionalLightShading);
        
        if (curShader == NULL)
        {
            LOG_ERROR("there's no shader designated\n");
            return false;
        }
        curShader->begin();
        
        // common uniforms
        glUniform3f(curShader->getUniformLocation("ambientLight.intensities"),
                    scene.ambientLight.intensity.x,
                    scene.ambientLight.intensity.y,
                    scene.ambientLight.intensity.z);
        
        glUniform3f(curShader->getUniformLocation("directionalLight.direction"),
                    scene.directionalLight.direction.x,scene.directionalLight.direction.y,scene.directionalLight.direction.z);
        
        glUniform3f(curShader->getUniformLocation("eyePosition"),scene.eyePosition.x,scene.eyePosition.y,scene.eyePosition.z);
        
        glUniform3f(curShader->getUniformLocation("directionalLight.intensities"),
                    scene.directionalLight.intensity.x,
                    scene.directionalLight.intensity.y,
                    scene.directionalLight.intensity.z);
        CZCheckGLError();
        
        draw(pRootNode, viewProjMat);
        CZCheckGLError();
        
        curShader->end();
#ifdef USE_OPENGL
        glColor3f(1.0,0.0,0.0);
        glPushMatrix();
        glTranslatef(scene.light.position.x, scene.light.position.y, scene.light.position.z);
        glDisable(GL_TEXTURE_2D);
        glutSolidSphere(2, 100, 100);
        glPopMatrix();
#endif
        
        return true;
    }
    
    bool Render::rawFrame(CZScene &scene,CZNode *pRootNode, CZMat4 &projMat)
    {
        curShader = getShader(kDirectionalLightShading);
        
        if (curShader == NULL)
        {
            LOG_ERROR("there's no shader designated\n");
            return false;
        }
        curShader->begin();
        
        // common uniforms
        glUniform3f(curShader->getUniformLocation("ambientLight.intensities"),
                    scene.ambientLight.intensity.x,
                    scene.ambientLight.intensity.y,
                    scene.ambientLight.intensity.z);
        
        glUniform3f(curShader->getUniformLocation("directionalLight.direction"),
                    scene.directionalLight.direction.x,scene.directionalLight.direction.y,scene.directionalLight.direction.z);
        
        glUniform3f(curShader->getUniformLocation("eyePosition"),scene.eyePosition.x,scene.eyePosition.y,scene.eyePosition.z);
        
        glUniform3f(curShader->getUniformLocation("directionalLight.intensities"),
                    scene.directionalLight.intensity.x,
                    scene.directionalLight.intensity.y,
                    scene.directionalLight.intensity.z);
        CZCheckGLError();
        
        draw(pRootNode, projMat);
        CZCheckGLError();
        
        curShader->end();
        
        return true;
    }
    
    bool Render::draw(CZNode *pNode, CZMat4 &viewProjMat)
    {
        if(pNode == nullptr)
        {
            LOG_ERROR("pNode is nullptr!\n");
            return false;
        }
        
        if(!pNode->isVisible) return true;
        bool result = false;
        
        // render children node
        const CZNode::NodeMap nodesChildren = pNode->getAllSubNodes();
        
        for(CZNode::NodeMap::const_iterator itr = nodesChildren.begin(); itr != nodesChildren.end(); itr ++)
        {
            result = draw(itr->second,viewProjMat) && result;
        }
        
        // render self
        switch (pNode->getType()) {
            case CZNode::kObjModel:
                result = drawObjModel(pNode, viewProjMat);
                break;
            case CZNode::kShape:
                result = drawShape(pNode,viewProjMat);
                break;
            default:
                break;
        }
        
        return result;
    }
    
    bool Render::drawObjModel(CZNode *pNode, CZMat4 &viewProjMat)
    {
        RenderResource* pCurRes = prepareObjNodeVAO(pNode);
        if(pCurRes == nullptr) return false;
        
        CZMat4 modelMat = pNode->getTransformMat();
        CZMat4 modelViewMat = pNode->modelViewMat * modelMat;
        
        CZObjModel *pCurNode = dynamic_cast<CZObjModel*>(pNode);
        if(pCurNode == nullptr)
        {
            LOG_ERROR("dynamic cast failed!\n");
            return false;
        }
        
        glUniformMatrix4fv(curShader->getUniformLocation("mvpMat"), 1, GL_FALSE, viewProjMat * modelViewMat);
        glUniformMatrix4fv(curShader->getUniformLocation("modelMat"), 1, GL_FALSE, modelMat);
        glUniformMatrix4fv(curShader->getUniformLocation("modelInverseTransposeMat"), 1, GL_FALSE, modelMat.GetInverseTranspose());
        
        GL_BIND_VERTEXARRAY(pCurRes->vao);
        
        for (vector<CZGeometry*>::iterator itr = pCurNode->geometries.begin(); itr != pCurNode->geometries.end(); itr++)
        {
            CZGeometry *pGeometry = *itr;
            CZMaterial *pMaterial = pCurNode->materialLib.get(pGeometry->materialName);
            
            float ke[4], ka[4], kd[4], ks[4], Ns = 10.0;
            if (pMaterial == NULL)
            {
                ka[0] = 0.2;    ka[1] = 0.2;    ka[2] = 0.2;
                kd[0] = 0.8;    kd[1] = 0.8;    kd[2] = 0.8;
                ke[0] = 0.0;    ke[1] = 0.0;    ke[2] = 0.0;
                ks[0] = 0.0;    ks[1] = 0.0;    ks[2] = 0.0;
                Ns = 10.0;
                LOG_ERROR("pMaterial is NULL\n");
            }
            else
            {
                for (int i=0; i<3; i++)
                {
                    ka[i] = pMaterial->Ka[i];
                    kd[i] = pMaterial->Kd[i];
                    ke[i] = pMaterial->Ke[i];
                    ks[i] = pMaterial->Ks[i];
                    Ns = pMaterial->Ns;
                }
            }
            glUniform3f(curShader->getUniformLocation("material.kd"), kd[0], kd[1], kd[2]);
            glUniform3f(curShader->getUniformLocation("material.ka"), ka[0], ka[1], ka[2]);
            glUniform3f(curShader->getUniformLocation("material.ke"), ke[0], ke[1], ke[2]);
            glUniform3f(curShader->getUniformLocation("material.ks"), ks[0], ks[1], ks[2]);
            glUniform1f(curShader->getUniformLocation("material.Ns"), Ns);
            
            int hasTex;
            if (pMaterial && enableTexture(pMaterial->texImage) && pGeometry->hasTexCoord)
                hasTex = 1;
            else	hasTex = 0;
            
            glUniform1i(curShader->getUniformLocation("hasTex"), hasTex);
            glUniform1i(curShader->getUniformLocation("tex"), 0);
            
            glDrawArrays(GL_TRIANGLES, (GLint)pGeometry->firstIdx, (GLsizei)pGeometry->vertNum);
            
        }
        
        GL_BIND_VERTEXARRAY(0);
        return true;
    }
    
    bool Render::drawShape(CZNode *pNode, CZMat4 &viewProjMat)
    {
        RenderResource* pCurRes = prepareShapeVAO(pNode);
        if(pCurRes == nullptr) return false;
        
        CZMat4 modelMat = pNode->getTransformMat();
        
        CZCube *pCube = dynamic_cast<CZCube*>(pNode);
        if(pCube == nullptr)
        {
            LOG_ERROR("dynamic cast failed!\n");
            return false;
        }
        
        glUniformMatrix4fv(curShader->getUniformLocation("mvpMat"), 1, GL_FALSE, viewProjMat * modelMat);
        glUniformMatrix4fv(curShader->getUniformLocation("modelMat"), 1, GL_FALSE, modelMat);
        glUniformMatrix4fv(curShader->getUniformLocation("modelInverseTransposeMat"), 1, GL_FALSE, modelMat.GetInverseTranspose());
        
        GL_BIND_VERTEXARRAY(pCurRes->vao);
        
        for (int i = 0; i < 6; i ++)
        {
            float ke[4], ka[4], ks[4], Ns = 10.0;
            ka[0] = 0.2;    ka[1] = 0.2;    ka[2] = 0.2;
            ke[0] = 0.0;    ke[1] = 0.0;    ke[2] = 0.0;
            ks[0] = 0.0;    ks[1] = 0.0;    ks[2] = 0.0;
            Ns = 10.0;
            
            glUniform3f(curShader->getUniformLocation("material.kd"), pCube->kd[i][0], pCube->kd[i][1], pCube->kd[i][2]);
            glUniform3f(curShader->getUniformLocation("material.ka"), ka[0], ka[1], ka[2]);
            glUniform3f(curShader->getUniformLocation("material.ke"), ke[0], ke[1], ke[2]);
            glUniform3f(curShader->getUniformLocation("material.ks"), ks[0], ks[1], ks[2]);
            glUniform1f(curShader->getUniformLocation("material.Ns"), Ns);
            glUniform1i(curShader->getUniformLocation("hasTex"), 0);
            glDrawElements(GL_TRIANGLE_STRIP, 4,  GL_UNSIGNED_BYTE, &pCube->indices[i*4]);
        }
        
        GL_BIND_VERTEXARRAY(0);
        CZCheckGLError();
        
        return true;
    }
    ////////////////////////////////////////
    
    bool Render::loadShaders()
    {
        //
        vector<string> attributes;
        attributes.push_back("vert");
        attributes.push_back("vertNormal");
        attributes.push_back("vertTexCoord");
        vector<string> uniforms;
        uniforms.push_back("mvpMat");
        uniforms.push_back("modelMat");
        uniforms.push_back("modelInverseTransposeMat");
        uniforms.push_back("ambientLight.intensities");
        uniforms.push_back("directionalLight.direction");
        uniforms.push_back("directionalLight.intensities");
        uniforms.push_back("eyePosition");
        uniforms.push_back("tex");
        uniforms.push_back("hasTex");
        uniforms.push_back("material.kd");
        uniforms.push_back("material.ka");
        uniforms.push_back("material.ke");
        uniforms.push_back("material.ks");
        uniforms.push_back("material.Ns");
        
        CZShader *pShader = new CZShader("standard","directionalLight",attributes,uniforms);
        shaders.insert(make_pair(kDirectionalLightShading,pShader));
        
        //
        attributes.clear();
        attributes.push_back("inPosition");
        attributes.push_back("inTexcoord");
        uniforms.clear();
        uniforms.push_back("mvpMat");
        uniforms.push_back("texture");
        uniforms.push_back("opacity");
        
        pShader = new CZShader("blit","blit",attributes,uniforms);
        shaders.insert(make_pair(kBlitImage,pShader));
        
        //
        attributes.clear();
        attributes.push_back("inPosition");
        uniforms.clear();
        uniforms.push_back("mvpMat");
        uniforms.push_back("inColor");
        
        pShader = new CZShader("blitColor","blitColor",attributes,uniforms);
        shaders.insert(make_pair(kBlitColor,pShader));
        
        CZCheckGLError();
        
        return true;
    }
    
    void Render::setSize(int w, int h)
    {
        if((w != width || h != height) && pBgImageRes)
        {
            delete pBgImageRes;
            pBgImageRes = nullptr;
        }
        
        width = w;	height = h;
        
        glViewport(0,0,width,height);
# ifdef _WIN32
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        gluPerspective(scene.cameraFov,(GLfloat)width/(GLfloat)height, scene.cameraNearPlane, scene.camearFarPlane);
        
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        
# endif
        
    }
    
    void Render::setGLSLDirectory(const char* glslDir)
    {
        if (glslDir == NULL)
        {
            LOG_WARN("glslDir is NULL\n");
            return;
        }
        
        CZShader::glslDirectory = string(glslDir);
    }
    
    CZShader* Render::getShader(ShaderType type)
    {
        ShaderMap::iterator itr = shaders.find(type);
        
        return itr != shaders.end() ?	itr->second : NULL;
    }
    
    RenderResource* Render::prepareObjNodeVAO(CZNode *pNode)
    {
        CZObjModel *pObjModel = dynamic_cast<CZObjModel*>(pNode);
        
        if(pObjModel == nullptr) return nullptr;
        
        GLResourceMap::iterator itr = resMap.find(pNode);
        if(itr != resMap.end()) return itr->second;
        
        RenderResource *pRes = new RenderResource;
        // vao
        GL_GEN_VERTEXARRAY(1, &pRes->vao);
        GL_BIND_VERTEXARRAY(pRes->vao);
        
        // vertex
        glGenBuffers(1, &pRes->vbo);
        glBindBuffer(GL_ARRAY_BUFFER, pRes->vbo);
        glBufferData(GL_ARRAY_BUFFER,pObjModel->vertexs.size() * sizeof(VertexData), pObjModel->vertexs.data(), GL_STATIC_DRAW);
        
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(VertexData), 0);
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(VertexData), reinterpret_cast<GLvoid*>(sizeof(CZVector3D<float>)));
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(VertexData), reinterpret_cast<GLvoid*>(sizeof(CZVector3D<float>)*2));
        CZCheckGLError();
        
        GL_BIND_VERTEXARRAY(0);
        
        resMap.insert(make_pair(pNode, pRes));
        
        return pRes;
    }
    
    RenderResource* Render::prepareShapeVAO(CZNode *pNode)
    {
        CZCube *pCube = dynamic_cast<CZCube*>(pNode);
        
        if(pCube == nullptr) return nullptr;
        
        GLResourceMap::iterator itr = resMap.find(pNode);
        if(itr != resMap.end()) return itr->second;
        
        RenderResource *pRes = new RenderResource;
        // vao
        GL_GEN_VERTEXARRAY(1, &pRes->vao);
        GL_BIND_VERTEXARRAY(pRes->vao);
        
        // vertex
        glGenBuffers(1, &pRes->vbo);
        glBindBuffer(GL_ARRAY_BUFFER, pRes->vbo);
        glBufferData(GL_ARRAY_BUFFER,pCube->vertexs.size() * sizeof(VertexData), pCube->vertexs.data(), GL_STATIC_DRAW);
        
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(VertexData), 0);
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(VertexData), reinterpret_cast<GLvoid*>(sizeof(CZVector3D<float>)));
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(VertexData), reinterpret_cast<GLvoid*>(sizeof(CZVector3D<float>)*2));
        CZCheckGLError();
        
        GL_BIND_VERTEXARRAY(0);
        
        resMap.insert(make_pair(pNode, pRes));
        
        return pRes;
    }
    
    bool Render::prepareBgImage(CZImage *bgImg)
    {
        if(bgImg == ptrBgImage) return true;
        
        // prepare texture
        TextureMap::iterator itr = textureMap.find(ptrBgImage);
        if(itr == textureMap.end())
        {
            LOG_WARN("Cannot find the texture of pre background image!\n");
            return false;
        }
        glDeleteTextures(1, &itr->second);
        textureMap.erase(itr);
        
        return true;
    }
    
    bool Render::prepareBgVAO()
    {
        // prepare vao
        const GLfloat vertices[] =
        {
            0.0, 0.0, 0.0, 0.0,
            (GLfloat)width, 0.0, 1.0, 0.0,
            0.0, (GLfloat)height, 0.0, 1.0,
            (GLfloat)width, (GLfloat)height, 1.0, 1.0,
        };
        
        if (pBgImageRes) return true;
        
        pBgImageRes = new RenderResource;
        GL_GEN_VERTEXARRAY(1, &pBgImageRes->vao);
        GL_BIND_VERTEXARRAY(pBgImageRes->vao);
        // create, bind, and populate VBO
        glGenBuffers(1, &pBgImageRes->vbo);
        glBindBuffer(GL_ARRAY_BUFFER, pBgImageRes->vbo);
        glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 16, vertices, GL_STATIC_DRAW);
        
        // set up attrib pointers
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, (void*)&vertices[0]);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, (void*)&vertices[8]);
        glEnableVertexAttribArray(1);
        
        glBindBuffer(GL_ARRAY_BUFFER,0);
        
        GL_BIND_VERTEXARRAY(0);
        CZCheckGLError();
        
        return true;
    }
    
    bool Render::enableTexture(CZImage* image)
    {
        if(image == NULL || image->data == NULL)
        {
            LOG_WARN("image is illegal\n");
            return false;
        }
        
        TextureMap::iterator itr = textureMap.find(image);
        
        if(itr == textureMap.end())
        {
            pair<TextureMap::iterator, bool> result = textureMap.insert(make_pair(image, -1));
            if(result.second) itr = result.first;
            else
            {
                LOG_ERROR("Insert new texture failed!\n");
                return false;
            }
            
            //generate an OpenGL texture ID for this texture
            glGenTextures(1, &itr->second);
            //bind to the new texture ID
            glBindTexture(GL_TEXTURE_2D, itr->second);
            //store the texture data for OpenGL use
            if (image->colorSpace == CZImage::RGBA) {
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)image->width , (GLsizei)image->height,
                             0, GL_RGBA, GL_UNSIGNED_BYTE, image->data);
            }
            else if (image->colorSpace == CZImage::RGB) {
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, (GLsizei)image->width , (GLsizei)image->height,
                             0, GL_RGB, GL_UNSIGNED_BYTE, image->data);
            }
            else if (image->colorSpace == CZImage::GRAY) {
                glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, (GLsizei)image->width , (GLsizei)image->height,
                             0, GL_LUMINANCE, GL_UNSIGNED_BYTE, image->data);
            }
            
            //	gluBuild2DMipmaps(GL_TEXTURE_2D, components, width, height, texFormat, GL_UNSIGNED_BYTE, bits);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            CZCheckGLError();
        }
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, itr->second);
        //glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
#if !defined(__APPLE__)
        glEnable(GL_TEXTURE_2D);
#endif
        
        return true;
    }
    
}