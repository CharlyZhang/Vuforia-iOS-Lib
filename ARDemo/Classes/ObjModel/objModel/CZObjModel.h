
#ifndef _CZOBJMODEL_H_
#define _CZOBJMODEL_H_

#include "CZNode.h"
#include "ObjModel.hpp"

namespace CZ3D {
    
/// CZObjModel
class CZObjModel : public ObjModel, public CZNode
{
public:
    CZObjModel();
    ~CZObjModel();
};
    
}
#endif