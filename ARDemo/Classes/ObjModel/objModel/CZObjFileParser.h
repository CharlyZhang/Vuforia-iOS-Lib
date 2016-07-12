/*CZObjFileParser.h
 help to parse files below:
 	*.obj
	*.mtl
 
 features£º
	1. read chars from file by lines
	2. each line begins with a prefix
	3. `#` indicates the comment line
	4. space and blank are allowed between lines
*/

#ifndef _CZOBJFILEPARSER_H_
#define _CZOBJFILEPARSER_H_

#include <fstream>
#include <string>
#include "CZLog.h"

class CZObjFileParser
{
public:
	/// \note: the 'process showing' part is not thread-safe, for usage of static variables
	virtual bool parseFile(const std::string& path);
	bool parseFile(const char* path);

protected:
	//@param is file stream, which is used fetch valid data (without prefix)
	//@param `ele_id` the prefix of each line, which determines data type
	virtual void parseLine(std::ifstream& ifs, const std::string& ele_id)
    {
        LOG_WARN("virtual function has not been impelemented!\n");
    }

	void skipLine(std::ifstream& is);
	bool skipCommentLine(std::ifstream& is);

	/* fetch an element, which is composed of chars between non-digitals or non-separators
	*	each element is divided by @param `sep`, and assigned @param `defaultValue` when no data presented between
	*	read the data before each `sep`
	*	read the latest non-digital and non-separator char and then pause
	*	ignore the data closed to EOF
	*@require `pData` has been allocated enough memory.
	*@param `maxCount` the max number of chars to read each time
	*@return the length of chars read
	*@promise the pointer of ifs is to the latest non-digital and non-separator char(including EOF), which can be queried by ifs.peek()
	*@promise ifs.good() equals true
	*
	*cases
	* input				data
	* 1/2/3`space`		 1,  2, 3
	* 1//3`space`		 1, -1, 3
	* 1/2`space`		 1,  2
	* 1`space`			 1
	* /EOF				-1
	* 1//3`space`		 1, -1
	* 1/2eof			 1		
	*/
	int parseNumberElement(std::ifstream &ifs, int *pData, char sep = '/', int defaultValue = -1, int maxCount = 3);

	std::string curDirPath;	//relative path(compared to the root directory of the project)
};

#endif
