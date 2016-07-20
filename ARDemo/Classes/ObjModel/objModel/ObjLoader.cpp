//
//  ObjLoader.cpp
//  Application3D
//
//  Created by CharlyZhang on 16/7/8.
//  Copyright © 2016年 CharlyZhang. All rights reserved.
//

#include "ObjLoader.hpp"
#include "../basic/CZVector.h"
#include "CZDefine.h"
#include <iostream>

using namespace std;

namespace CZ3D {
    
CZGeometry* ObjLoader::pCurGeometry = nullptr;
CZObjModel* ObjLoader::pCurModel = nullptr;
ObjLoader ObjLoader::objLoader;                     //< 里

bool ObjLoader::load(CZObjModel *objModel, std::string &path)
{
    if (objModel == nullptr)
    {
        LOG_ERROR("objModel is nullptr!\n");
        return false;
    }
    
    pCurGeometry = nullptr;
    pCurModel = objModel;
    
    return objLoader.parseFile(path);
}

bool ObjLoader::loadFromTemp(CZObjModel *objModel, std::string &path)
{
    if (objModel == nullptr)
    {
        LOG_ERROR("objModel is nullptr!\n");
        return false;
    }
    
    pCurGeometry = nullptr;
    pCurModel = objModel;
    
    // load binary file
    FILE *fp = fopen(path.c_str(), "rb");
    
    if (fp == NULL)
    {
        LOG_DEBUG("there's no binary data for this model\n");
        return false;
    }
    
    unsigned char mtlLibNameLen;
    fread((char*)&mtlLibNameLen, sizeof(unsigned char), 1, fp);
    pCurModel->mtlLibName.resize(mtlLibNameLen+1);
    fread((char*)pCurModel->mtlLibName.c_str(), sizeof(char), mtlLibNameLen, fp);
    
    
    // geometry
    unsigned short count;
    fread((char*)(&count), sizeof(count), 1, fp);
    
    long totalVertNum = 0;
    for (int iGeo = 0; iGeo < count; iGeo++)
    {
        CZGeometry *pNewGeometry = new CZGeometry();
        
        // hasTexcoord
        fread(&(pNewGeometry->hasTexCoord), sizeof(bool), 1, fp);
        
        // material name
        unsigned char mtlLibNameLen;
        
        fread(&mtlLibNameLen, sizeof(unsigned char), 1, fp);
        pNewGeometry->materialName.resize(mtlLibNameLen+1);
        fread((char*)pNewGeometry->materialName.c_str(), sizeof(char), mtlLibNameLen, fp);
        
        // data
        long numVert;
        fread(&numVert, sizeof(numVert), 1, fp);
        
        pNewGeometry->firstIdx = totalVertNum;
        pNewGeometry->vertNum = numVert;
        totalVertNum +=  numVert;
        
        pCurModel->geometries.push_back(pNewGeometry);
    }
    
    
    fread(&(totalVertNum), sizeof(totalVertNum), 1, fp);
    
//    pCurModel->positions.resize(totalVertNum);
//    pCurModel->normals.resize(totalVertNum);
//    pCurModel->texcoords.resize(totalVertNum);
//    fread(pCurModel->positions.data(), sizeof(CZVector3D<float>), totalVertNum, fp);
//    fread(pCurModel->normals.data(), sizeof(CZVector3D<float>), totalVertNum, fp);
//    fread(pCurModel->texcoords.data(), sizeof(CZVector2D<float>), totalVertNum, fp);
    
    // material
    fread((char*)(&count), sizeof(count), 1, fp);
    
    for (int i = 0; i < count; i++)
    {
        // material name
        unsigned char mtlNameLen;
        string materialName;
        fread(&mtlNameLen, sizeof(unsigned char), 1, fp);
        materialName.resize(mtlNameLen+1);
        fread((char*)materialName.c_str(), sizeof(char), mtlNameLen, fp);
        
        // material
        CZMaterial *pMaterial = new CZMaterial;
        fread((char*)&pMaterial->Ns, sizeof(float), 1, fp);
        fread((char*)pMaterial->Ka, sizeof(float), 4, fp);
        fread((char*)pMaterial->Kd, sizeof(float), 4, fp);
        fread((char*)pMaterial->Ks, sizeof(float), 4, fp);
        bool hasTexture;
        fread((char*)&hasTexture, sizeof(bool), 1, fp);
        if (hasTexture)
        {
            int w,h;
            fread((char*)&w, sizeof(int), 1, fp);
            fread((char*)&h, sizeof(int), 1, fp);
            char colorComponentNum;
            CZImage::ColorSpace colorSpace;
            fread(&colorComponentNum, sizeof(char), 1, fp);
            switch (colorComponentNum)
            {
                case 3:
                    colorSpace = CZImage::RGB;
                    break;
                case 4:
                    colorSpace = CZImage::RGBA;
                    break;
                case 1:
                    colorSpace = CZImage::GRAY;
                    break;
            }
            CZImage *image = new CZImage(w,h,colorSpace);
            fread((char*)image->data, sizeof(unsigned char), w*h*colorComponentNum, fp);
            pMaterial->texImage = image;
        }
        
        pCurModel->materialLib.setMaterial(materialName, pMaterial);
    }
    
    fclose(fp);
    
    return true;
}

bool ObjLoader::saveToTemp(CZObjModel *objModel, const string& path)
{
    if (objModel == nullptr)
    {
        LOG_ERROR("objModel is nullptr!\n");
        return false;
    }
    
    FILE *fp = fopen(path.c_str(), "wb");
    
    if (fp == NULL)
    {
        LOG_ERROR("file open failed\n");
        return false;
    }
    // material lib name
    unsigned char mtlLibNameLen = objModel->mtlLibName.size();
    fwrite((char*)&mtlLibNameLen, sizeof(unsigned char), 1, fp);
    fwrite((char*)objModel->mtlLibName.c_str(), sizeof(char), mtlLibNameLen, fp);
    
    // geometry
    unsigned short count = objModel->geometries.size();
    fwrite((char*)(&count), sizeof(count), 1, fp);
    for (vector<CZGeometry*>::iterator itr = objModel->geometries.begin(); itr != objModel->geometries.end(); itr++)
    {
        CZGeometry *p = *itr;
        // hasTexcoord
        fwrite(&(p->hasTexCoord), sizeof(bool), 1, fp);
        // material name
        unsigned char mtlNameLen = p->materialName.size();
        fwrite(&mtlNameLen, sizeof(unsigned char), 1, fp);
        fwrite(p->materialName.c_str(), sizeof(char), mtlNameLen, fp);
        
        // data
        fwrite(&(p->vertNum), sizeof(p->vertNum), 1, fp);
    }
    
    // data
//    long totalVertNum = objModel->positions.size();
//    fwrite(&(totalVertNum), sizeof(totalVertNum), 1, fp);
//    fwrite(objModel->positions.data(), sizeof(CZVector3D<float>), totalVertNum, fp);
//    fwrite(objModel->normals.data(), sizeof(CZVector3D<float>), totalVertNum, fp);
//    fwrite(objModel->texcoords.data(), sizeof(CZVector2D<float>), totalVertNum, fp);
    
    // material
    CZMaterialMap materialMap = objModel->materialLib.getAll();
    count = materialMap.size();
    fwrite((char*)(&count), sizeof(count), 1, fp);
    for (CZMaterialMap::iterator itr = materialMap.begin(); itr != materialMap.end(); itr++)
    {
        // material name
        string materialName = itr->first;
        unsigned char mtlNameLen = materialName.size();
        fwrite(&mtlNameLen, sizeof(unsigned char), 1, fp);
        fwrite(materialName.c_str(), sizeof(char), mtlNameLen, fp);
        // material
        CZMaterial *pMaterial = itr->second;
        fwrite((char*)&pMaterial->Ns, sizeof(float), 1, fp);
        fwrite((char*)pMaterial->Ka, sizeof(float), 4, fp);
        fwrite((char*)pMaterial->Kd, sizeof(float), 4, fp);
        fwrite((char*)pMaterial->Ks, sizeof(float), 4, fp);
        bool hasTexture;
        if(pMaterial->texImage)
        {
            hasTexture = true;
            fwrite((char*)&hasTexture, sizeof(bool), 1, fp);
            int w = pMaterial->texImage->width;
            int h = pMaterial->texImage->height;
            fwrite((char*)&w, sizeof(int), 1, fp);
            fwrite((char*)&h, sizeof(int), 1, fp);
            char colorComponentNum;
            switch (pMaterial->texImage->colorSpace)
            {
                case CZImage::RGB:
                    colorComponentNum = 3;
                    break;
                case CZImage::RGBA:
                    colorComponentNum = 4;
                    break;
                case CZImage::GRAY:
                    colorComponentNum = 1;
                    break;
            }
            fwrite(&colorComponentNum, sizeof(char),1,fp);
            fwrite((char*)pMaterial->texImage->data, sizeof(unsigned char), w*h*colorComponentNum, fp);
        }
        else
        {
            hasTexture = false;
            fwrite((char*)&hasTexture, sizeof(bool), 1, fp);
        }
    }
    
    fclose(fp);
    
    return true;
}
////////////////////

bool ObjLoader::parseFile(const string& path)
{
    LOG_INFO("Parsing %s ...\n", path.c_str());
    
    if(CZObjFileParser::parseFile(path) == false) return false;
    
    pCurModel->unpackRawData();
    
    /// load material lib
    pCurModel->materialLib.parseFile(curDirPath + "/" + pCurModel->mtlLibName);
    
    pCurModel->clearRawData();
    
    return true;
}


///////////////////////////

void ObjLoader::parseLine(ifstream& ifs, const string& ele_id)
{
    if ("mtllib" == ele_id)
        parseMaterialLib(ifs);
    else if ("usemtl" == ele_id)
        parseUseMaterial(ifs);
    else if ("v" == ele_id)
        parseVertex(ifs);
    else if ("vt" == ele_id)
        parseVertexTexCoord(ifs);
    else if ("vn" == ele_id)
        parseVertexNormal(ifs);
    else if ("f" == ele_id)
        parseFace(ifs);
    else
        skipLine(ifs);
}

void ObjLoader::parseMaterialLib(std::ifstream &ifs)
{
    ifs >> pCurModel->mtlLibName;
    LOG_INFO("	mtllib %s \n", pCurModel->mtlLibName.c_str());
}

void ObjLoader::parseUseMaterial(std::ifstream &ifs)
{
    CZGeometry *pNewGeometry = new CZGeometry();
    pCurGeometry = pNewGeometry;
    ifs >> pNewGeometry->materialName;
    pCurModel->geometries.push_back(pNewGeometry);
    LOG_INFO("	usemtl %s\n",pNewGeometry->materialName.c_str());
}

void ObjLoader::parseVertex(std::ifstream &ifs)
{
    float x, y, z;
    ifs >> x >> y >> z;
    
    pCurModel->m_vertRawVector.push_back(CZVector3D<float>(x, y, z));
}

void ObjLoader::parseVertexNormal(std::ifstream &ifs)
{
    float x, y, z;
    ifs >> x >> y >> z;
    
    if (!ifs.good()) {                     // in case it is -1#IND00
        x = y = z = 0.0;
        ifs.clear();
        skipLine(ifs);
    }
    pCurModel->m_normRawVector.push_back(CZVector3D<float>(x, y, z));
}

void ObjLoader::parseVertexTexCoord(std::ifstream &ifs)
{
    float x, y;
    ifs >> x >> y;
    ifs.clear();                           // is z (i.e. w) is not available, have to clear error flag.
    
    pCurModel->m_texRawVector.push_back(CZVector2D<float>(x, y));
}

void ObjLoader::parseFace(std::ifstream &ifs)
{
    CZFace face;
    int data[3] = { -1, -1, -1 };
    int count;
    
    for (int i = 0; i < 3; i++){
        count = parseNumberElement(ifs, data);
        face.addVertTexNorm(data[0], data[1], data[2]);
    }
    skipLine(ifs);
    
    pCurGeometry->addFace(face);
    
    ifs.clear();
}
    
}
