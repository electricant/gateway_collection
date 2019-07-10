/*
 * Simple standalone class that is capable to authenticate a user against
 * networks employing fortinet hardware.
 *
 * Usage:
 * 1) Create this class using its constructor and supply username and password.
 * 2) Call the authenticate() method
 * 3) If authentication is successful refresh the "keepalive" URL as needed with
 *    the method refresh()
 *
 * Copyright (C) 2015 Electric Ant <electricant@anche.no>
 */
#include <exception>
#include <string>
#include <sstream>
#include <cstring>	// for memset
#include <cstdlib>	// for atoi()
/* Used for socket I/O */
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h> 

// address used to test connectivity
#define TEST_ADDRESS "www.example.com"
// size of the receive buffer
#define BUF_SIZE (3*1024)
// User-Agent for HTTP requests
#define USER_AGENT "Lilith-Daemon"

class Authenticator {
	public:
		static const int AUTH_SUCCESS      = 0;
		static const int ALREADY_CONNECTED = -1;
		static const int AUTH_FAIL         = -2;

	private:
		const char* REFRESH_TOKEN = "location.href=\"http://";
		std::string refreshURL;
		struct authInfo {
			std::string username;
			std::string password;
			std::string magic;
			std::string hostname;
		}info;

	public:
		Authenticator(std::string username, std::string password);
		/*
		 * Authenticate using the username and password supplied.
		 * Returns a status code telling the state of the client.
		 */
		int authenticate();
		/*
		 * Refresh the "keepalive" URL. User must be authenticated before
		 * calling this function, otherwhise InvalidURLException will be thrown
		 */
		void refresh();
	
	private:
		/* Send an HTTP get request to the host and store the response into
		 * receiveBuffer.
		 * Returns the number of bytes read.
		 * 
		 * host - Hostname for the request in the form address:port. If no port
		 *        is specified it is assumed to be 80
		 */
		int HTTPget(char* receiveBuffer, size_t bufLength, std::string host, 
				std::string path = "/");
		/* Send an HTTP post request to the host and store the response into
		* receiveBuffer
 		* Returns the number of bytes read.
 		* 
 		* data - Post data (already encoded!)
 		* host - Hostname for the request in the form address:port. If no port
		*        is specified it is assumed to be 80
 		*/
		int HTTPpost(char* receiveBuffer, size_t bufLength, std::string data,
				std::string host, std::string path = "/");
		/*
		 * To authenticate the server needs a 'magic' token to be sent 
		 * alongside the username and password. Such token is extracted from
		 * the response. It is passed in the redirect URL as a parameter.
		 *
		 * NOTE: this function does not recognize a login response from
		 * something different. This shall be done before calling this routine.
		 */
		std::string getMagicStr(char* data);
		/*
		 * Read the body of the response in order to extract the host for
		 * authentication. The host is returned in the form name:port.
		 *
		 * NOTE: as getMagicStr() it assumes the data is a login response.
		 */
		std::string getAuthHost(char* data);
		/*
		 * This function is responsible for the actual authentication.
		 * It sends the user's credentials and parses the answer to determine
		 * wether or not the authentication was successful.
		 * Returns a status code, like authenticate()
		 */
		 int doAuth();
};

class NetworkException : public std::exception
{
	private:
		const char* _what;
	public:
		NetworkException()
		{
			_what = "Something went wrong with the network";
		}
		NetworkException(const char* whatStr)
		{
			_what = whatStr;
		}
		virtual const char* what() const throw()
		{
			return _what;
		}
};

class InvalidURLException : public std::exception
{
    private:
        const char* _what;
    public:
        InvalidURLException()
        {
            _what = "The URL to refresh seems to be wrong. Are you"
					"authenticated?";
        }
        InvalidURLException(const char* whatStr)
        {
            _what = whatStr;
        }
        virtual const char* what() const throw()
        {
            return _what;
        }
};

