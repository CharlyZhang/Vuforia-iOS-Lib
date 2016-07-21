#include "CZObjModel.h"

using namespace std;

namespace CZ3D {
    
CZObjModel::CZObjModel(): CZNode(kObjModel)
{

}
CZObjModel::~CZObjModel()
{
	LOG_DEBUG("destructing CZObjModel (%ld)\n", (long)this);
}

}
