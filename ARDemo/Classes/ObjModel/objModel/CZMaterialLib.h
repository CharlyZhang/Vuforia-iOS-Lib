#ifndef _CZMATERIALLIB_H_
#define _CZMATERIALLIB_H_

#include "CZObjFileParser.h"
#include "CZMaterial.h"

#include <map>

namespace CZ3D {
    
typedef std::map<std::string, CZMaterial*> CZMaterialMap;

/// CZMaterial library 
class CZMaterialLib : public CZObjFileParser
{
public:
	CZMaterial* get(std::string &name);
	const CZMaterialMap& getAll();
    bool setMaterial(std::string &mtlName, CZMaterial *pMaterial);
    
	CZMaterialLib() {	m_pCur = NULL;	}
	~CZMaterialLib();

private:
	//TO DO: deal with m_pCur == nullptr when there's no `newmtl` in the file
	void parseLine(std::ifstream& ifs, const std::string& ele_id) override;
	
	CZMaterial *m_pCur;

	CZMaterialMap m_materials;
};

}
#endif