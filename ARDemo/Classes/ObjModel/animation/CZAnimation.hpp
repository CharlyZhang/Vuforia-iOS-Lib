//
//  CZAnimation.hpp
//  Application3D
//
//  Created by CharlyZhang on 16/6/29.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#ifndef CZAnimation_hpp
#define CZAnimation_hpp

#include "../basic/CZDefine.h"
#include <string>

namespace NAMESPACE {
    
class CZAnimation
{
public:
    // define type
    typedef enum _AnimationType {
        kShapeAnimaiton
    } AnimationType;
    
    CZAnimation();
    
    virtual void update(long time) = 0;
    virtual void start(std::string &name) = 0;
    virtual void stop();
    virtual void play();
    virtual void pause();
    
    bool isPlaying() {return _isPlaying;}
    
protected:
    bool _isPlaying;
};

}
#endif /* CZAnimation_hpp */
