//
//  ModelFactory.cpp
//  Application3D
//
//  Created by CharlyZhang on 16/7/8.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#include "ModelFactory.hpp"
#include "../basic/CZDefine.h"
#include "ObjLoader.hpp"

#include <string>

using namespace std;

CZObjModel* ModelFactory::createObjModel(const char* filename)
{
    if(filename == NULL)
    {
        LOG_ERROR("filename is NULL\n");
        return nullptr;
    }
    
    CZObjModel *pModel = new CZObjModel;
    
    bool success = false;
    string strFileName(filename);
    success = ObjLoader::load(pModel, strFileName);
    if(success) return pModel;
    
    delete pModel;
    return nullptr;
}

CZObjModel* ModelFactory::createObjModelFromTemp(const char* filename)
{
    if(filename == NULL)
    {
        LOG_ERROR("filename is NULL\n");
        return nullptr;
    }
    
    CZObjModel *pModel = new CZObjModel;
    
    bool success = false;
    string strFileName(filename);
    success = ObjLoader::loadFromTemp(pModel, strFileName);
    if(success) return pModel;
    
    delete pModel;
    return nullptr;
}