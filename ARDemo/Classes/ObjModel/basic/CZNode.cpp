//
//  CZNode.cpp
//  Application3D
//
//  Created by CharlyZhang on 16/6/29.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#include "CZNode.h"


CZNode::CZNode(NodeType t /*= kEmpty*/): _type(t)
{
    m_vao = -1;
    m_vboPos = -1;
    m_vboNorm = -1;
    m_vboTexCoord = -1;
    parentNode = nullptr;
}

CZNode::~CZNode()
{
    if(m_vao != -1) GL_DEL_VERTEXARRAY(1, &m_vao);
    if(m_vboPos != -1) glDeleteBuffers(1, &m_vboPos);
    if(m_vboNorm != -1) glDeleteBuffers(1, &m_vboNorm);
    if(m_vboTexCoord != -1) glDeleteBuffers(1, &m_vboTexCoord);
    
    for(NodeMap::iterator itr = _childrenNodes.begin(); itr != _childrenNodes.end(); itr ++)
    {
        delete itr->second;
    }
    
    _childrenNodes.clear();
    
}

void CZNode::resetMatrix()
{
    rotateMat.LoadIdentity();
    translateMat.LoadIdentity();
    scaleMat.LoadIdentity();
    
    for(NodeMap::iterator itr = _childrenNodes.begin(); itr != _childrenNodes.end(); itr ++)
    {
        itr->second->resetMatrix();
    }

}

CZMat4 CZNode::getTransformMat()
{
    if(parentNode == nullptr)
        return translateMat * scaleMat * rotateMat;
    else
        return parentNode->getTransformMat() * translateMat * scaleMat * rotateMat;
}

bool CZNode::addSubNode(std::string &name,CZNode *node)
{
    if(node == nullptr)
    {
        LOG_ERROR("node is nullptr!\n");
        return false;
    }
    
    NodeMap::iterator itr = _childrenNodes.find(name);
    if(itr != _childrenNodes.end())
    {
        LOG_WARN("Node with name(%s) has existed and will be replaced!\n",name.c_str());
    }
    
    _childrenNodes[name] = node;
    node->parentNode = this;
    return true;
}

bool CZNode::removeSubNode(std::string &name)
{
    NodeMap::iterator itr = _childrenNodes.find(name);
    if(itr == _childrenNodes.end())
    {
        LOG_WARN("Cannot find node with name(%s)!\n",name.c_str());
        return false;
    }
    
    _childrenNodes.erase(itr);
    
    return true;
}

bool CZNode::removeAllSubNodesOfType(NodeType type)
{
    for(NodeMap::iterator itr = _childrenNodes.begin(); itr != _childrenNodes.end(); itr ++)
    {
        if(itr->second->getType() == type)
        {
            delete itr->second;
            itr = _childrenNodes.erase(itr);
        }
    }
    
    return true;
}

const CZNode::NodeMap & CZNode::getAllSubNodes()
{
    return _childrenNodes;
}

CZNode * CZNode::getNode(std::string &name)
{
    NodeMap::iterator itr = _childrenNodes.find(name);
    if(itr == _childrenNodes.end())
    {
        LOG_WARN("Cannot find node with name(%s)!\n",name.c_str());
        return nullptr;
    }
    
    return itr->second;
}

bool CZNode::draw(CZShader *pShader, CZMat4 &viewProjMat)
{
    if(pShader == NULL)
    {
        LOG_ERROR("pShader is NULL!\n");
        return false;
    }
    
    bool result = true;
    for(NodeMap::iterator itr = _childrenNodes.begin(); itr != _childrenNodes.end(); itr ++)
    {
        result = itr->second->draw(pShader, viewProjMat) && result;
    }
    
    return result;
}