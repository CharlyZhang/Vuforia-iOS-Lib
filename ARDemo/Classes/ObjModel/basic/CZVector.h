
#ifndef _CZVECTOR_H_
#define _CZVECTOR_H_

#include <iostream>
#include <cmath>

namespace CZ3D {
    
template <class T>
class CZVector3D
{
public:
	T x,y,z;

	CZVector3D(T x_=0, T y_=0, T z_=0): x(x_), y(y_), z(z_){};

	bool  operator<( const  CZVector3D<T> & p_) const
	{
		if ( this->x < p_.x )
		{
			return true;
		} 
		else if ( this->x==p_.x && this->y < p_.y )
		{
			return true;
		}
		else if ( this->x==p_.x && this->y==p_.y && this->z<p_.z )
		{
			return true;
		} 
		else
		{
			return false;
		}
	}
	bool  operator==( const  CZVector3D<T> & p_) const 
	{
		if ( this->x==p_.x && this->y==p_.y && this->z==p_.z )
		{
			return true;
		} 
		else
		{
			return false;
		}
	}
	CZVector3D<T>&  operator=( const  CZVector3D<T> & p_) 
	{
		this->x = p_.x; 
		this->y = p_.y;
		this->z = p_.z;
		return *this;
	}
	

	/// Here we overload operators 
	inline CZVector3D<T> operator+(CZVector3D<T> vVector){	return CZVector3D<T>(vVector.x + x, vVector.y + y, vVector.z + z);}
	inline CZVector3D<T> operator-(CZVector3D<T> vVector){	return CZVector3D<T>(x - vVector.x, y - vVector.y, z - vVector.z);}
	inline CZVector3D<T> operator*(T num){	return CZVector3D<T>(x * num, y * num, z * num);}
	inline T operator*(CZVector3D<T> vVector){	return (x*vVector.x+y*vVector.y+z*vVector.z);}
	inline CZVector3D<T> operator/(T num){	return CZVector3D<T>(x / num, y / num, z / num);}

	/// Here we overload the iostream
	friend std::ostream& operator<<(std::ostream &ostr, CZVector3D<T> v){	return ostr << "(" <<v.x << " " << v.y << " " << v.z << ")";}
	friend std::istream& operator>>(std::istream &istr, CZVector3D<T> &v){	return istr >> v.x >> v.y >> v.z;	}

	///cast to pointer to T for glVertex4fv etc
	operator T* () const {return (T*) this;}
	operator const T* () const {return (const T*) this;}

	T magnitude() {	return (T)sqrt(x*x + y*y + z*z);}
	T length() { return magnitude();}

	void normalize() {	*this = *this / magnitude();}
	
	CZVector3D<T> cross(CZVector3D<T> vVector)
	{
		CZVector3D<T> vCross;                

		vCross.x = ((this->y * vVector.z) - (this->z * vVector.y));

		vCross.y = ((this->z * vVector.x) - (this->x * vVector.z));

		vCross.z = ((this->x * vVector.y) - (this->y * vVector.x));

		return vCross;  
	}
};


template <class T>
class CZVector2D
{
public:
	T x,y;

	CZVector2D(T x_=0, T y_=0): x(x_), y(y_){};

	bool  operator<( const  CZVector2D<T> & p_) const
	{
		if ( this->x < p_.x )
		{
			return true;
		} 
		else if ( this->x==p_.x && this->y < p_.y )
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	bool  operator==( const  CZVector2D<T> & p_) const
	{
		if ( this->x==p_.x && this->y==p_.y)
		{
			return true;
		} 
		else
		{
			return false;
		}
	}
	CZVector2D<T>&  operator=( const  CZVector2D<T> & p_) 
	{
		this->x = p_.x; 
		this->y = p_.y;

		return *this;
	}

	/// Here we overload operators 
	inline CZVector2D<T> operator+(CZVector2D<T> vVector)	{ return CZVector2D<T>(vVector.x + x, vVector.y + y);}
	inline CZVector2D<T> operator-(CZVector2D<T> vVector)	{ return CZVector2D<T>(x - vVector.x, y - vVector.y);}
	inline CZVector2D<T> operator*(T num)	{ return CZVector2D<T>(x * num, y * num);}
	inline T operator*(CZVector2D<T> vVector)	{ return (x*vVector.x+y*vVector.y);}
	inline CZVector2D<T> operator/(T num)	{ return CZVector2D<T>(x / num, y / num); }

	/// Here we overload the iostream
	friend std::ostream& operator<<(std::ostream &ostr, CZVector2D<T> v){	return ostr << "(" <<v.x << " " << v.y << ")";}
	friend std::istream& operator>>(std::istream &istr, CZVector2D<T> &v){	return istr >> v.x >> v.y;}

	///cast to pointer to T for glVertex4fv etc
	operator T* () const {return (T*) this;}
	operator const T* () const {return (const T*) this;}

	/// 求级数
	T magnitude() {	return (T)sqrt(x*x + y*y);}
	/// 规范化本点
	void normalize() {	*this = *this / magnitude();}
};

}
#endif