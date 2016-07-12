
#ifndef _CZOBJMODEL_H_
#define _CZOBJMODEL_H_

#include <string>
#include <vector>
#include "CZVector.h"
#include "CZObjFileParser.h"
#include "CZGeometry.h"
#include "CZMaterialLib.h"
#include "CZShader.h"
#include "CZMat4.h"
#include "CZNode.h"
#include "ObjModel.hpp"

/// CZObjModel
class CZObjModel : public ObjModel, public CZNode
{
public:
	CZObjModel();
	~CZObjModel();
    
	bool draw(CZShader *pShader, CZMat4 &viewProjMat) override;
    
    void transform2GCard();
};
#endif