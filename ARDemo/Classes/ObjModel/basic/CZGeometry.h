#ifndef __GEMORETRY_HPP__
#define __GEMORETRY_HPP__

#include "CZVector.h"
#include <vector>
#include <string>

/// CZFace
class CZFace
{
public:
	CZFace()
	{
		v.reserve(3);
		vt.reserve(3);
		vn.reserve(3);
	}

    ~CZFace() {	std::vector<int> temp; v.clear(); vt.clear(); vn.clear(); v.swap(temp); vt.swap(temp); vn.swap(temp); }

	void addVertTexNorm(int vi, int ti, int ni)
	{
		v.push_back(vi);
		vt.push_back(ti);
		vn.push_back(ni);
	}

	std::vector<int> v;		///<	vertex indices
	std::vector<int> vt;	///<	texture indices
	std::vector<int> vn;	///<	normal indices
};

/// CZGeometry
class CZGeometry
{
public:

	CZGeometry();
	~CZGeometry();

	void addFace(const CZFace& face)
	{
		if (face.vn[0] != -1)	hasNormal = true;
		if (face.vt[0] != -1)	hasTexCoord = true;

		faces.push_back(face);
	}
	/// unpack the raw data
    long unpackRawData(const std::vector<CZVector3D<float> > &posRawVector,	\
                       const std::vector<CZVector3D<float> > &normRawVector,	\
                       const std::vector<CZVector2D<float> > &texCoordRawVector, \
                       std::vector<CZVector3D<float> > &outPositions, \
                       std::vector<CZVector3D<float> > &outNormals, \
                       std::vector<CZVector2D<float> > &outTexcoords);

	std::vector<CZFace> faces;			///< faces
	CZVector3D<float> aabbMin,aabbMax;	///< aabb bounding box
	std::string materialName;			///< material name

	bool hasNormal;
	bool hasTexCoord;
    
    long firstIdx;
    long vertNum;

private:
	/// generate face normals 
    void generateFaceNorm(std::vector<CZVector3D<float> > &positions,std::vector<CZVector3D<float> > &outNormals);
	/// update aabb
	void updateAABB(CZVector3D<float> p);
};

#endif
