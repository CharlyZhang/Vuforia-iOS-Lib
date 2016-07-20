
///  \file CZShader.h
///  \brief This is the file declare the Class CZShader.
///
///		(description)
///
///  \version	1.0.0
///	 \author	Charly Zhang<chicboi@hotmail.com>
///  \date		2014-09-17
///  \note

#ifndef __CZSHADER_H_
#define __CZSHADER_H_

#include <vector>
#include <string>
#include <map>

namespace CZ3D {
    
class CZShader
{
public:
    static std::string glslDirectory;
    
	/// shader without binding `attribute` and `uniform`
	CZShader(const char* vertFileName, const char* fragFileName);
	/// shader with binding `attribute` and `uniform`
	CZShader(const char* vertFileName, const char* fragFileName, \
		std::vector<std::string>& atrributes, std::vector<std::string>& uniforms, bool contentDirectly = false);

	~CZShader();
	void begin();
	void end();
	unsigned int getAttributeLocation(const char* atrrName);
	unsigned int getUniformLocation(const std::string& str);
	bool isReady(){ return m_ready;}

private:
	/// destroy shaders
	void destroyShaders(unsigned int vertShader,unsigned int fragShader, unsigned int prog);
	/// read shader code from files
	bool textFileRead(const char *_fn, char *&_shader);
	/// init OpenGL extension
	///		\note should be called after the initialization of `OpenGL` and `glut`
	///				for, it contains `glew`
	static bool initOpenGLExtensions();
	/// whether GLSL supported
	static bool hasGLSLSupport();
	bool compile();

	static bool extensionsInit;			///< indicate whether GL extension initial is done
	static bool useGLSL;				///< indicate whether GLSL is ready
	static bool bGeometryShader;		///< indicate whether G-Shader is supported
	static bool bGPUShader4;			///< indicate whether Shader4 is supported

	char *m_VertexShader;
	char *m_FragmentShader;

	unsigned int m_Program;
	unsigned int m_Vert,m_Frag;

	bool isCompiled;					///< indicate whether shader compliation
	bool m_ready;
	std::map<std::string,unsigned int> m_uniforms;
};

}
#endif