//
//  ModelFactory.hpp
//  Application3D
//
//  Created by CharlyZhang on 16/7/8.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#ifndef ModelFactory_hpp
#define ModelFactory_hpp

class CZObjModel;

class ModelFactory
{
public:
    static CZObjModel* createObjModel(const char* filename);
    static CZObjModel* createObjModelFromTemp(const char* filename);
};


#endif /* ModelFactory_hpp */
