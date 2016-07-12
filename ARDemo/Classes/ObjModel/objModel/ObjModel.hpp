//
//  ObjModel.hpp
//  Application3D
//
//  Created by CharlyZhang on 16/7/8.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#ifndef ObjModel_hpp
#define ObjModel_hpp

#include "../basic/CZVector.h"
#include "../basic/CZGeometry.h"
#include "CZMaterialLib.h"
#include <vector>

class ObjLoader;

class ObjModel
{
public:
    friend class ObjLoader;
    ObjModel();
    ~ObjModel();
    
protected:
    void clearRawData();
    void unpackRawData();                 ///< to make `vert`, `normal` and `texcoord` share the same amount of data
    
    std::string mtlLibName;							///< material lib name
    
    // raw data
    std::vector<CZVector3D<float>> m_vertRawVector;
    std::vector<CZVector3D<float>> m_normRawVector;
    std::vector<CZVector2D<float>> m_texRawVector;

public:
    CZMaterialLib materialLib;

    std::vector<CZGeometry*> geometries;

    std::vector<CZVector3D<float> > positions;
    std::vector<CZVector3D<float> > normals;
    std::vector<CZVector2D<float> > texcoords;
};

#endif /* ObjModel_hpp */
