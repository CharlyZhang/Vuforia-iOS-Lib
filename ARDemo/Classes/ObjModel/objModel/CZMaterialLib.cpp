#include "CZMaterialLib.h"
#include "CZLog.h"

#include <string>

using namespace std;

void CZMaterialLib::parseLine(ifstream& ifs, const string& ele_id)
{
	if ("newmtl" == ele_id) {
		string mtlName;
		ifs >> mtlName;
		LOG_INFO("newmtl %s\n",mtlName.c_str());

		CZMaterial *pNewMtl = new CZMaterial();
		m_materials.insert(pair<string, CZMaterial*>(mtlName, pNewMtl));
		m_pCur = pNewMtl;
	}
	else if ("Ns" == ele_id) {	//shininess
		ifs >> m_pCur->Ns;
	}
    else if ("Ke" == ele_id) {	//ambient color
        ifs >> m_pCur->Ke[0] >> m_pCur->Ke[1] >> m_pCur->Ke[2];
        ifs.clear();
    }
	else if ("Ka" == ele_id) {	//ambient color
		ifs >> m_pCur->Ka[0] >> m_pCur->Ka[1] >> m_pCur->Ka[2];
		ifs.clear();
	}
	else if ("Kd" == ele_id) {	//diffuse color
		ifs >> m_pCur->Kd[0] >> m_pCur->Kd[1] >> m_pCur->Kd[2];
		ifs.clear();
	}
	else if ("Ks" == ele_id) {	//specular color
		ifs >> m_pCur->Ks[0] >> m_pCur->Ks[1] >> m_pCur->Ks[2];
		ifs.clear();
	}
	else if ("map_Kd" == ele_id) {
		string texImgName,texImgPath;
		ifs >> texImgName;	

		texImgPath = curDirPath + "/" + texImgName;
		CZImage *image = CZLoadTexture(texImgPath);
		if(image)
        {
            LOG_INFO(" texture(%s) loaded successfully\n",texImgName.c_str());
            m_pCur ->texImage = image;
        }
    }
//    else if ("map_Ka" == ele_id) {
//        string texImgName,texImgPath;
//        ifs >> texImgName;
//        
//        texImgPath = curDirPath + "/" + texImgName;
//        CZImage *image = CZLoadTexture(texImgPath);
//        if(image)
//        {
//            LOG_INFO(" texture(%s) loaded successfully\n",texImgName.c_str());
//            m_pCur -> setTextureImage(image);
//        }
//    }
	else
		skipLine(ifs);
}

CZMaterial* CZMaterialLib::get(string &name)
{
	auto iterMtl = m_materials.find(name);
	return iterMtl != m_materials.end() ? iterMtl->second : nullptr;
}

const map<std::string, CZMaterial*>& CZMaterialLib::getAll()
{
	return m_materials;
}

bool CZMaterialLib::setMaterial(std::string &mtlName, CZMaterial *pMaterial)
{
    m_materials[mtlName] = pMaterial;
    return true;
}

CZMaterialLib::~CZMaterialLib()
{
	for (auto iterMtl = m_materials.begin(); iterMtl != m_materials.end(); iterMtl++)
	{
		delete iterMtl->second;
	}
}