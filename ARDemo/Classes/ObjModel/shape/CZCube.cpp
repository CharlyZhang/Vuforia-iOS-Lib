//
//  CZCube.cpp
//  Application3D
//
//  Created by CharlyZhang on 16/6/29.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#include "CZCube.hpp"
#include "../basic/CZLog.h"

using namespace std;

namespace CZ3D {
    
unsigned char CZCube::indices[] = {0,1,2,3,
                                    0,2,4,6,
                                    2,3,6,7,
                                    0,1,4,5,
                                    4,5,6,7,
                                    1,3,5,7};

CZCube::CZCube()
{
    vertexs.clear();
}

CZCube::~CZCube()
{
    vertexs.clear();
}

void CZCube::create(CZPoint3D &origin, float width, float length, float height)
{
    /// create original data
    vector<CZPoint3D> positions,normals;
    for(int i = 0; i < 8; i ++)
    {
        int w = i & 1;
        int l = (i & 2) >> 1;
        int h = (i & 4) >> 2;
        
        VertexData vert;
        // points' position and normal
        CZPoint3D offset(width*((float)w-0.5f),length*((float)l-0.5f),height*((float)h-0.5f));
        vert.position = origin + offset;
    
        offset.normalize();
        vert.normal = offset;
        
        vertexs.push_back(vert);
    }
    
    for(auto i = 0; i < 6; i++)
    {
        kd[i][0] = 1.0f * rand() / RAND_MAX;
        kd[i][1] = 1.0f * rand() / RAND_MAX;
        kd[i][2] = 1.0f * rand() / RAND_MAX;
        kd[i][3] = 1.0f;
    }
}

}