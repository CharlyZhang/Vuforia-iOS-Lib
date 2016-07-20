#ifndef _CZAPPLICATION3D_H_
#define _CZAPPLICATION3D_H_

#include <string>
#include <map>
#include "CZBasic.h"
#include "CZObjFileParser.h"
#include "CZShader.h"
#include "CZMat4.h"
#include "CZNode.h"
#include "CZObjModel.h"
#include "CZAnimaitonManager.hpp"
#include "Render.hpp"

namespace CZ3D {
    
    class Application3D : private CZObjFileParser
    {
    public:
        Application3D();
        ~Application3D();
        
        bool init(const char *glslDir, const char* sceneFilename = NULL);
        bool loadObjModel(const char* nodeName, const char* filepath, bool quickLoad = true);
        bool setNodeVisible(const char* nodeName, bool visible);
        bool clearObjModel();
        bool setRenderBufferSize(int w, int h);
        void frame();
        void reset();
        
        void rawFrame(CZMat4 &projMat);
        void setNodeMVMat(const char* nodeName, CZMat4 &mvMat);
        void hideAllSubNodes();
        
        // shape
        bool createShape(const char* shapeFileName, bool contentInParam = false);
        bool clearShapes();
        void animateShape();
        
#ifdef	__ANDROID__
        bool createShader(ShaderType type,const char* vertFile, const char* fragFile, std::vector<std::string> &attributes,std::vector<std::string> &uniforms);
        void setImageLoader(const char * cls, const char * method);
        void setModelLoadCallBack(const char * cls, const char *method);
#endif
        
        // document directory
        //  /note : default as the same of model's location;
        //          should be set in ios platform to utilize binary data
        void setDocDirectory(const char* docDir);
        
        // control
        //	/note : (deltaX,deltaY) is in the screen coordinate system
        void rotate(float deltaX, float deltaY, const char *nodeName = nullptr);
        void translate(float deltaX, float deltaY, const char *nodeName = nullptr);
        void scale(float s, const char *nodeName = nullptr);
        
        // custom config
        void setBackgroundColor(float r, float g, float b, float a);
        void setBackgroundImage(CZImage *img);
        void setModelColor(float r, float g, float b, float a);
        
        // camera
        void setCameraPosition(float x, float y, float z);
        
        // light
        void setLightPosition(float x, float y, float z);   ///< TO DEPRECATED
        void setLigthDirection(float x, float y, float z);
        void setAmbientColor(unsigned char r, unsigned char g, unsigned char b);
        void setDiffuseColor(unsigned char r, unsigned char g, unsigned char b);
        
        static bool enableTexture(CZImage* image);
        
    private:
        void parseLine(std::ifstream& ifs, const std::string& ele_id) override;
        void parseEyePosition(std::ifstream& ifs);
        void parseCameraFov(std::ifstream& ifs);
        void parseCameraNearPlane(std::ifstream& ifs);
        void parseCameraFarPlane(std::ifstream& ifs);
        void parsePointLight(std::ifstream& ifs);
        void parseDirectionalLight(std::ifstream& ifs);
        void parseBackgroundColor(std::ifstream& ifs);
        void parseMainColor(std::ifstream& ifs);
        
    private:
        CZScene scene;
        CZNode rootNode;
        CZAnimationManager animationManager;
        CZ3D::Render render;
        CZImage *backgroundImage;
        char *documentDirectory;                          ///< to store the binary data of model
    };
    
}
#endif