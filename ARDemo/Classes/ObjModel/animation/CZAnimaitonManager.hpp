//
//  CZAnimaitonManager.hpp
//  Application3D
//
//  Created by CharlyZhang on 16/6/29.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#ifndef CZAnimaitonManager_hpp
#define CZAnimaitonManager_hpp

#include "CZAnimation.hpp"
#include "CZNode.h"
#include <map>
#include <string>

namespace CZ3D {
    
class CZAnimationManager
{
public:
    typedef std::map<std::string, CZAnimation*> AnimationsMap;
    
    ~CZAnimationManager();
    
    bool registerAnimation(std::string &name, CZAnimation* anim);
    bool unRegisterAnimation(std::string &name);
    
    void update(long time);       //< ms
    
private:
    AnimationsMap _animationsMap;
};

}
#endif /* CZAnimaitonManager_hpp */
