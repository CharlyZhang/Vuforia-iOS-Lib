//
//  CZAnimaitonManager.cpp
//  Application3D
//
//  Created by CharlyZhang on 16/6/29.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#include "CZAnimaitonManager.hpp"
#include "../basic/CZLog.h"

using namespace std;

namespace CZ3D {
    
CZAnimationManager::~CZAnimationManager()
{
    for(AnimationsMap::iterator itr = _animationsMap.begin(); itr != _animationsMap.end(); itr ++)
    {
        delete itr->second;
    }
    
    _animationsMap.clear();
}

bool CZAnimationManager::registerAnimation(string &name,CZAnimation* anim)
{
    if(anim == nullptr)
    {
        LOG_ERROR("animation is nullptr!\n");
        return false;
    }
    
    AnimationsMap::iterator itr = _animationsMap.find(name);
    if(itr != _animationsMap.end())
    {
        LOG_WARN("the animation has been registered and will be replaced!\n");
    }
    
    _animationsMap[name] = anim;
    
    return true;
}

bool CZAnimationManager::unRegisterAnimation(string &name)
{
    AnimationsMap::iterator itr = _animationsMap.find(name);
    if(itr == _animationsMap.end()) return false;
    _animationsMap.erase(itr);
    return true;
}

void CZAnimationManager::update(long time)
{
    for(AnimationsMap::iterator itr = _animationsMap.begin(); itr != _animationsMap.end(); itr ++)
    {
        itr->second->update(time);
    }
}
    
}