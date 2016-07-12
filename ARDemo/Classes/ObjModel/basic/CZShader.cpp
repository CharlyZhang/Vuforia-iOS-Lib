
///  \file CZShader.cpp
///  \brief This is the file implement the Class CZShader.
///
///		(description)
///
///  \version	1.0.0
///	 \author	Charly Zhang<chicboi@hotmail.com>
///  \date		2014-09-17
///  \note
#include <cstdlib>
#include "CZShader.h"
#include "CZDefine.h"
#include "CZLog.h"

using namespace std;

bool CZShader::extensionsInit = true;
bool CZShader::useGLSL = true;
bool CZShader::bGeometryShader = false;
bool CZShader::bGPUShader4 = false;
string CZShader::glslDirectory = DEFAULT_GLSL_DIR;

void printShaderInfoLog(GLuint obj);
void printProgramInfoLog(GLuint obj);


CZShader::CZShader(const char* vertFileName, const char* fragFileName)
{
    initOpenGLExtensions();
    
    this->m_VertexShader = NULL;
    this->m_FragmentShader = NULL;
    this->m_Program = 0;
    this->m_Frag = 0;
    this->m_Vert = 0;
    m_ready = false;
    
    if(!textFileRead(vertFileName,m_VertexShader))	return;
    if(!textFileRead(fragFileName,m_FragmentShader))return;
    
    
    //create shader object
    m_Vert = glCreateShader(GL_VERTEX_SHADER);
    m_Frag = glCreateShader(GL_FRAGMENT_SHADER);
    
    //create program object
    m_Program = glCreateProgram();
    
    if(!compile())
    {
        printShaderInfoLog(m_Vert);
        printShaderInfoLog(m_Frag);
        destroyShaders(m_Vert,m_Frag,m_Program);
        return;
    }
    
    //attach shader to program
    glAttachShader(m_Program,m_Vert);
    glAttachShader(m_Program,m_Frag);
    
    //link program
    glLinkProgram(m_Program);
    printProgramInfoLog(m_Program);
    
    // release vertex and fragment shaders
    if (m_Vert)
    {
        glDeleteShader(m_Vert);
        m_Vert = 0;
    }
    if (m_Frag)
    {
        glDeleteShader(m_Frag);
        m_Frag = 0;
    }

    m_ready = true;
}

CZShader::CZShader(const char* vertFileName, const char* fragFileName, \
                   vector<string>& attributes, vector<string>& uniforms,bool contentDirectly /* = false*/)
{
    initOpenGLExtensions();
    
    this->m_VertexShader = NULL;
    this->m_FragmentShader = NULL;
    this->m_Program = 0;
    this->m_Frag = 0;
    this->m_Vert = 0;
    m_ready = false;

    if (contentDirectly)
    {
        if(vertFileName == nullptr ||  fragFileName == nullptr)
        {
            LOG_ERROR("Error: vertFile or fragFile is empty!\n");
            return;
        }

        size_t len = strlen(vertFileName);
        m_VertexShader = new char[len+1];
        strcpy(m_VertexShader,vertFileName);
        m_VertexShader[len] = '\0';

        len = strlen(fragFileName);
        m_FragmentShader = new char[len+1];
        strcpy(m_FragmentShader,fragFileName);
        m_FragmentShader[len] = '\0';
    }
    else
    {
        char fileName[1024];
        strcpy(fileName,glslDirectory.c_str());
        strcat(fileName,vertFileName);
        strcat(fileName,".vert");
        if(!textFileRead(fileName,m_VertexShader))	return;

        strcpy(fileName,glslDirectory.c_str());
        strcat(fileName,fragFileName);
        strcat(fileName,".frag");
        if(!textFileRead(fileName,m_FragmentShader))return;
    }

    CZCheckGLError();
    
    //create shader object
    m_Vert = glCreateShader(GL_VERTEX_SHADER);
    m_Frag = glCreateShader(GL_FRAGMENT_SHADER);
    
    //create program object
    m_Program = glCreateProgram();
    
    if(!compile())
    {
        LOG_ERROR("shader compile failed!\n");
        destroyShaders(m_Vert,m_Frag,m_Program);
        return;
    }
    
    //attach shader to program
    glAttachShader(m_Program,m_Vert);
    glAttachShader(m_Program,m_Frag);
    
    //bind attributes
    for(unsigned int i=0; i<attributes.size(); i++)
    {
        glBindAttribLocation(m_Program, (GLuint) i, (const GLchar*) attributes[i].c_str());
        CZCheckGLError();
    }
    
    //link program
    GLint linkStatus;
    glLinkProgram(m_Program);
    glGetProgramiv(m_Program, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == 0)
    {
        LOG_ERROR("shader link failed!\n");
        printProgramInfoLog(m_Program);
        destroyShaders(m_Vert, m_Frag, m_Program);
        return;
    }
    
    //bind uniform objects
    for(unsigned int i=0; i<uniforms.size(); i++)
    {
        GLuint location = glGetUniformLocation(m_Program, uniforms[i].c_str());
        CZCheckGLError();
        m_uniforms[uniforms[i]] = location;
    }
    
    // release vertex and fragment shaders
    if (m_Vert)
    {
        glDetachShader(m_Program, m_Vert);
        glDeleteShader(m_Vert);
        m_Vert = 0;
    }
    if (m_Frag)
    {
        glDetachShader(m_Program, m_Frag);
        glDeleteShader(m_Frag);
        m_Frag = 0;
    }
    
    CZCheckGLError();
    m_ready = true;
}

CZShader::~CZShader()
{
    if(NULL != m_VertexShader)
        delete[] m_VertexShader;
    if(NULL != m_FragmentShader)
        delete[] m_FragmentShader;
    
    //delete program
    glDeleteProgram(m_Program);
}

/// destroy shaders
void CZShader::destroyShaders(GLuint vertShader,GLuint fragShader, GLuint prog)
{
    if(vertShader) { glDeleteShader(vertShader); vertShader = 0;};
    if(fragShader) { glDeleteShader(fragShader); fragShader = 0;};
    if(prog) {  glDeleteProgram(prog); prog = 0;};
}

bool CZShader::textFileRead(const char *_fn, GLchar *&_shader)
{
    if(NULL == _fn)
        return false;
    
    FILE *fp;
    size_t count = 0;
    
    fp = fopen(_fn,"rt");
    if(NULL == fp)
    {
        LOG_ERROR("shader file not exists!\n");
        return false;
    }
    
    // move the file pointer to the end of file stream
    fseek(fp,0,SEEK_END);
    // count the offset from begin to end
    count = ftell(fp);
    // rewind the file pointer and set it to the begin
    rewind(fp);
    
    if(count<=0)
        return false;
    
    _shader = new GLchar[count+1];
    count = fread(_shader,sizeof(GLchar),count,fp);
    _shader[count] = '\0';
    fclose(fp);
    return true;
}

/// init OpenGL extension
bool CZShader::initOpenGLExtensions()
{
#ifdef USE_OPENGL
    if (extensionsInit) return true;
    extensionsInit = true;
    
    GLenum err = glewInit();
    CZCheckGLError();
    
    if (GLEW_OK != err)
    {
        LOG_ERROR("%s\n",glewGetErrorString(err));
        extensionsInit = false;
        return false;
    }
    
    hasGLSLSupport();
#endif
    return true;
}

/// whether GLSL supported
bool CZShader::hasGLSLSupport()
{
#ifdef USE_OPENGL
    if (useGLSL) return true;							///< already initialized and GLSL is available
    useGLSL = true;
    
    initOpenGLExtensions();								///< extensions were not yet initialized!!
    
    
    if(GLEW_VERSION_3_2)
    {
        LOG_INFO("OpenGL 3.2 (or higher) is available!\n");
        useGLSL = true;
        bGeometryShader = true;
        bGPUShader4 = true;
        LOG_INFO("[OK] OpenGL Shading Language is available!\n\n");
        return true;
    }
    else if(GLEW_VERSION_3_1)
    {
        LOG_INFO("OpenGL 3.1 core functions are available!\n");
    }
    else if(GLEW_VERSION_3_0)
    {
        LOG_INFO("OpenGL 3.0 core functions are available!\n");
    }
    else if(GLEW_VERSION_2_1)
    {
        LOG_INFO("OpenGL 2.1 core functions are available!\n");
    }
    else if (GLEW_VERSION_2_0)
    {
        LOG_INFO("OpenGL 2.0 core functions are available!\n");
    }
    else if (GLEW_VERSION_1_5)
    {
        LOG_INFO("OpenGL 1.5 core functions are available\n");
    }
    else if (GLEW_VERSION_1_4)
    {
        LOG_INFO("OpenGL 1.4 core functions are available\n");
    }
    else if (GLEW_VERSION_1_3)
    {
        LOG_INFO("OpenGL 1.3 core functions are available\n");
    }
    else if (GLEW_VERSION_1_2)
    {
        LOG_INFO("OpenGL 1.2 core functions are available\n");
    }
    
    /// if we have opengl ver < 3.2, need to load extensions.
    LOG_INFO("Checking for Extensions: \n");
    
    //Extensions supported
    if (!glewIsSupported("GL_ARB_fragment_shader"))
    {
        LOG_INFO("[WARNING] GL_ARB_fragment_shader extension is not available!\n");
        useGLSL = false;
    }else{
        LOG_INFO("[OK] GL_ARB_fragment_shader extension is available!\n");
        
    }
    
    if (!glewIsSupported("GL_ARB_vertex_shader"))
    {
        LOG_INFO("[WARNING] GL_ARB_vertex_shader extension is not available!\n");
        useGLSL = false;
    }else{
        LOG_INFO("[OK] GL_ARB_vertex_shader extension is available!\n");
    }
    
    if (!glewIsSupported("GL_ARB_shader_objects"))
    {
        LOG_INFO("[WARNING] GL_ARB_shader_objects extension is not available!\n");
        useGLSL = false;
    }else{
        LOG_INFO("[OK] GL_ARB_shader_objects extension is available!\n");
    }
    
    
    if (!glewIsSupported("GL_ARB_geometry_shader4"))
    {
        LOG_INFO("[WARNING] GL_ARB_geometry_shader4 extension is not available!\n");
        bGeometryShader = false;
    }else{
        LOG_INFO("[OK] GL_ARB_geometry_shader4 extension is available!\n");
        bGeometryShader = true;
    }
    
    if(!glewIsSupported("GL_EXT_gpu_shader4")){
        LOG_INFO("[WARNING] GL_EXT_gpu_shader4 extension is not available!\n");
        bGPUShader4 = false;
    }else{
        LOG_INFO("[OK] GL_EXT_gpu_shader4 extension is available!\n");
        bGPUShader4 = true;
    }
    
    ///end detecting extensions
    if (useGLSL)
    {
        LOG_INFO("[OK] OpenGL Shading Language is available!\n\n");
    }
    else
    {
        LOG_INFO("[FAILED] OpenGL Shading Language is not available...\n\n");
    }
#endif
    return useGLSL;
}

void printShaderInfoLog(GLuint obj)
{
    int infologLength = 0;
    int charsWritten  = 0;
    char *infoLog;
    
    glGetShaderiv(obj, GL_INFO_LOG_LENGTH,&infologLength);
    
    if (infologLength > 0)
    {
        infoLog = (char *)malloc(infologLength);
        glGetShaderInfoLog(obj, infologLength, &charsWritten, infoLog);
        LOG_INFO("%s",infoLog);
        free(infoLog);
    }
}
void printProgramInfoLog(GLuint obj)
{
    int infologLength = 0;
    int charsWritten  = 0;
    char *infoLog;
    
    glGetProgramiv(obj, GL_INFO_LOG_LENGTH,&infologLength);
    
    if (infologLength > 0)
    {
        infoLog = (char *)malloc(infologLength);
        glGetProgramInfoLog(obj, infologLength, &charsWritten, infoLog);
        LOG_INFO("%s",infoLog);
        free(infoLog);
    }
}

bool CZShader::compile()
{
    if (!useGLSL) return false;
    
    if (m_VertexShader == NULL || m_FragmentShader == NULL) {
        LOG_ERROR("shader source is NULL!\n");
        return false;
    }
    
    isCompiled = false;
    
    GLint compiled = 0;
    
    const GLchar *vv = m_VertexShader;
    const GLchar *ff = m_FragmentShader;
    GLint	vertLen = (GLint) strlen((const char*)vv);
    GLint	fragLen = (GLint) strlen((const char*)ff);
    
    //���shader
    glShaderSource(m_Vert,1,&vv, &vertLen);
    glShaderSource(m_Frag,1,&ff, &fragLen);
    
    //����shader
    glCompileShader(m_Vert);
    glGetShaderiv(m_Vert, GL_COMPILE_STATUS, &compiled);
    if (compiled)       isCompiled = true;
    printShaderInfoLog(m_Vert);
    
    glCompileShader(m_Frag);
    glGetShaderiv(m_Vert, GL_COMPILE_STATUS, &compiled);
    if (!compiled)      isCompiled = false;
    printShaderInfoLog(m_Frag);
    
    CZCheckGLError();
    
    if(NULL != m_VertexShader) {	delete[] m_VertexShader;	m_VertexShader = NULL;}
    if(NULL != m_FragmentShader){	delete[] m_FragmentShader;	m_FragmentShader = NULL;}
    
    return isCompiled;
}

void CZShader::begin()
{
    glUseProgram(m_Program);
}

void CZShader::end()
{
    glUseProgram(0);
}

GLuint CZShader::getAttributeLocation(const char* atrrName)
{
    return glGetAttribLocation(m_Program, atrrName);
}

GLuint CZShader::getUniformLocation(const string& str)
{
    return m_uniforms[str];
}