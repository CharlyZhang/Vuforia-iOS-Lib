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

namespace CZ3D {
    
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
    
    // raw data
    std::vector<CZVector3D<float>> m_vertRawVector;
    std::vector<CZVector3D<float>> m_normRawVector;
    std::vector<CZVector2D<float>> m_texRawVector;
    
public:
    std::string mtlLibName;							///< material lib name
    CZMaterialLib materialLib;
    
    std::vector<CZGeometry*> geometries;
    std::vector<VertexData> vertexs;
};
    
}

#endif /* ObjModel_hpp */
