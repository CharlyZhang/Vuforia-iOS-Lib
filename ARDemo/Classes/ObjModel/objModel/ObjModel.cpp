//
//  ObjModel.cpp
//  Application3D
//
//  Created by CharlyZhang on 16/7/8.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#include "ObjModel.hpp"

using namespace std;

namespace CZ3D {
    
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
    vector<VertexData> temp1;
    vertexs.clear();
    vertexs.swap(temp1);
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
    vertexs.clear();
    
    long totalVertNum = 0;
    for (vector<CZGeometry*>::iterator itr = geometries.begin(); itr != geometries.end(); itr++)
    {
        CZGeometry *pGeometry = (*itr);
        long vertNum = pGeometry->unpackRawData(m_vertRawVector, m_normRawVector, m_texRawVector, vertexs);
        pGeometry->firstIdx = totalVertNum;
        totalVertNum += vertNum;
    }
}

}