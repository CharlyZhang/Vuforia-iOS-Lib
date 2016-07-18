#include "CZObjModel.h"
#include "CZMaterial.h"
#include "CZLog.h"
//#include "Application3D.h"
#include "CZDefine.h"

using namespace std;

namespace IAR {
    
CZObjModel::CZObjModel(): CZNode(kObjModel)
{

}
CZObjModel::~CZObjModel()
{
	
}

bool CZObjModel::draw(CZShader* pShader, CZMat4 &viewProjMat)
{
    if(CZNode::draw(pShader, viewProjMat) != true) return false;

    CZMat4 modelMat = getTransformMat();
    glUniformMatrix4fv(pShader->getUniformLocation("mvpMat"), 1, GL_FALSE, viewProjMat * modelMat);
    glUniformMatrix4fv(pShader->getUniformLocation("modelMat"), 1, GL_FALSE, modelMat);
    glUniformMatrix4fv(pShader->getUniformLocation("modelInverseTransposeMat"), 1, GL_FALSE, modelMat.GetInverseTranspose());
    
    GL_BIND_VERTEXARRAY(m_vao);

    for (vector<CZGeometry*>::iterator itr = geometries.begin(); itr != geometries.end(); itr++)
    {
        CZGeometry *pGeometry = *itr;
        CZMaterial *pMaterial = materialLib.get(pGeometry->materialName);
        
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
		glUniform3f(pShader->getUniformLocation("material.kd"), kd[0], kd[1], kd[2]);
        glUniform3f(pShader->getUniformLocation("material.ka"), ka[0], ka[1], ka[2]);
        glUniform3f(pShader->getUniformLocation("material.ke"), ke[0], ke[1], ke[2]);
        glUniform3f(pShader->getUniformLocation("material.ks"), ks[0], ks[1], ks[2]);
        glUniform1f(pShader->getUniformLocation("material.Ns"), Ns);
        
        int hasTex = 0;
//        if (pMaterial && Application3D::enableTexture(pMaterial->texImage) && pGeometry->hasTexCoord)
//            hasTex = 1;
//        else	hasTex = 0;
        
        glUniform1i(pShader->getUniformLocation("hasTex"), hasTex);
        glUniform1i(pShader->getUniformLocation("tex"), 0);
        
		glDrawArrays(GL_TRIANGLES, (GLint)pGeometry->firstIdx, (GLsizei)pGeometry->vertNum);
     
    }
    
    GL_BIND_VERTEXARRAY(0);
    
    return true;
}

void CZObjModel::transform2GCard()
{
    // vao
    GL_GEN_VERTEXARRAY(1, &m_vao);
    GL_BIND_VERTEXARRAY(m_vao);
    
    // vertex
    glGenBuffers(1, &m_vboPos);
    glBindBuffer(GL_ARRAY_BUFFER, m_vboPos);
    glBufferData(GL_ARRAY_BUFFER,positions.size() * 3 * sizeof(GLfloat), positions.data(), GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    CZCheckGLError();
    
    // normal
    glGenBuffers(1, &m_vboNorm);
    glBindBuffer(GL_ARRAY_BUFFER, m_vboNorm);
    glBufferData(GL_ARRAY_BUFFER, normals.size() * 3 * sizeof(GLfloat), normals.data(), GL_STATIC_DRAW);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);
    CZCheckGLError();
    
    // texcoord
    glGenBuffers(1, &m_vboTexCoord);
    glBindBuffer(GL_ARRAY_BUFFER, m_vboTexCoord);
    glBufferData(GL_ARRAY_BUFFER, texcoords.size() * 2 * sizeof(GLfloat), texcoords.data(), GL_STATIC_DRAW);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, 0);
    CZCheckGLError();
    
    GL_BIND_VERTEXARRAY(0);
}
    
}

