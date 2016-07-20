//
//  CZAnimation.cpp
//  Application3D
//
//  Created by CharlyZhang on 16/6/29.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#include "CZAnimation.hpp"

namespace CZ3D {

CZAnimation::CZAnimation(): _isPlaying(false)
{
}

void CZAnimation::stop()
{
    _isPlaying = false;
}

void CZAnimation::play()
{
    _isPlaying = true;
}

void CZAnimation::pause()
{
    _isPlaying = false;
}
    
}