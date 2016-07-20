//
//  CZShape.h
//  Application3D
//
//  Created by CharlyZhang on 16/6/29.
//  Copyright © 2016年 Founder. All rights reserved.
//

#ifndef CZShape_h
#define CZShape_h

#include "CZNode.h"

namespace CZ3D {
    
class CZShape : public CZNode
{
public:
    CZShape(): CZNode(kShape), isAnimating(false){};
    
    /// properties
    bool isAnimating;
};

}
#endif /* CZShape_h */
