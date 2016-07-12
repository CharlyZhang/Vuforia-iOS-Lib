//
//  ObjModel.cpp
//  Application3D
//
//  Created by CharlyZhang on 16/7/8.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#include "ObjModel.hpp"

using namespace std;

ObjModel::ObjModel()
{
    mtlLibName = "Not Set";
}

ObjModel::~ObjModel()
{
    // geometry
    for (vector<CZGeometry*>::iterator itr = geometries.begin(); itr != geometries.end(); itr++)
    {
        delete *itr;
    }
    geometries.clear();
    vector<CZGeometry*> temp;
    geometries.swap(temp);
    
    clearRawData();
    vector<CZVector3D<float>> temp1;
    vector<CZVector2D<float>> temp2;
    positions.clear();
    positions.swap(temp1);
    normals.clear();
    normals.swap(temp1);
    texcoords.clear();
    texcoords.swap(temp2);
}

void ObjModel::clearRawData()
{
    /*free memory£∫
     *£®link£∫http://www.cppblog.com/lanshengsheng/archive/2013/03/04/198198.html£©
     */
    
    m_vertRawVector.clear();
    vector<CZVector3D<float>> temp3D;
    vector<CZVector2D<float>> temp2D;
    m_vertRawVector.swap(temp3D);
    
    m_texRawVector.clear();
    m_texRawVector.swap(temp2D);
    
    m_normRawVector.clear();
    m_normRawVector.swap(temp3D);
}

void ObjModel::unpackRawData()
{
    positions.clear();
    normals.clear();
    texcoords.clear();
    
    long totalVertNum = 0;
    for (vector<CZGeometry*>::iterator itr = geometries.begin(); itr != geometries.end(); itr++)
    {
        CZGeometry *pGeometry = (*itr);
        long vertNum = pGeometry->unpackRawData(m_vertRawVector, m_normRawVector, m_texRawVector, \
                                                positions,normals,texcoords);
        pGeometry->firstIdx = totalVertNum;
        totalVertNum += vertNum;
    }
}