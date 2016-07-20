#include "CZObjFileParser.h"
#include "CZLog.h"

using namespace std;

namespace CZ3D {
    
bool CZObjFileParser::parseFile(const string& path)
{
	ifstream ifs(path.c_str(), ios::in | ios::ate);
	if (!ifs)
	{
		LOG_WARN("%s not exist\n",path.c_str());
		return false;
	}

	curDirPath = path.substr(0, path.find_last_of('/'));
    string filename = path.substr(path.find_last_of('/')+1,path.length()-path.find_last_of('/')-1);

    size_t fileSize = (size_t)ifs.tellg();
	ifs.seekg(0, ios::beg);

	//	explain what's going on
	LOG_INFO("Parsing %s  (size = %ld bytes)...\n", path.c_str(), (long int)fileSize);

	// and go.
	static size_t lastPercent = 0;
	size_t percent = 10;	//	progress indicator
	while (skipCommentLine(ifs))
	{
		// show progress for files larger than one Mo
		if ((fileSize > 1024 * 1024) && (100 * ifs.tellg() / fileSize >= percent)) {
			percent = 100 * (size_t)ifs.tellg() / fileSize;
			percent = (percent / 10) * 10;

			if (lastPercent != percent)
			{
				LOG_INFO("processing \'%s\' %ld%%\n",filename.c_str(),(long int)percent);
				lastPercent = percent;
			}
		}

		string ele_id;
		if (!(ifs >> ele_id))
			break;
		else
			parseLine(ifs, ele_id);
	}

	return true;
}

bool CZObjFileParser::parseFile(const char *filename)
{
	if(filename == NULL)
	{
		LOG_WARN("filename is NULL\n");
		return false;
	}
	
	string strFilename(filename);
	return parseFile(strFilename);
}

void CZObjFileParser::skipLine(ifstream& is)
{
	char next;
	is >> std::noskipws;
	while ((is >> next) && ('\n' != next));
}

bool CZObjFileParser::skipCommentLine(ifstream& is)
{
	char next;
	while (is >> std::skipws >> next)
	{
		is.putback(next);
		if ('#' == next)
			skipLine(is);
		else
			return true;
	}
	return false;
}

/*usage£ºifstream::operator >> (int&)
handle different cases after ignoring spaces and blanks:
*								|			  original			|		   after clear() 
*case(RegEx)			example	|read£¿	good()?	eof()?	peek()	|good()?	eof()?	peek()
*<digit>+ <non-digital>		123a|T		T		F		a		|
*<digit>0 <non-digital>		a	|F		F		F		EOF		|T			F		a
*<digit>+ </eof>		123/eof	|T		F		T		EOF		|T			F		EOF
*<digit>0 </eof>		/eof	|F		F		T		EOF		|T			F		EOF 
*
*cases should be taken into consideration while implementing `parseNumberElement()`*/
int CZObjFileParser::parseNumberElement(ifstream &ifs, int *pData, char sep, int defaultValue, int maxCount)
{
	int count = 0;
	int data;
	char c;/// used for skipping spaces and blanks

	/*steps in every loop:
	*1. whether count+1; whether fill with default value
	*2. whether continue (yes when next char is `sep`)
	*3. whether should call ifs.clear()*/
	while (true){
		ifs >> data;
		if (ifs.good()){//case 1: "<digit>+ <non-digital>"
			pData[count++] = data;
			if (ifs.peek() != sep)
				break;
			else
				ifs.get(c);
		}
		else{
			if (!ifs.eof()){//case 2: "<digit>0 <non-digital>"
				ifs.clear();
				pData[count++] = defaultValue;
				if (ifs.peek() != sep)
					break;
				else
					ifs.get(c);
			}
			else{// case3 4 (with /eof), dump it whether there're data
				ifs.clear();
				break;
			}
		}
	}

	return count;
}

}