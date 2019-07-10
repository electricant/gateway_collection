/*
 * Implementation for the Authenticator class.
 * see authenticator.h for details
 *
 * Copyright (C) 2015 Electric Ant <electricant@anche.no>
 */
#include "authenticator.h"

// Constructor
Authenticator::Authenticator(std::string username, std::string password)
{
	info.username = username;
	info.password = password;
}

// public authentication function. Check for connectivity and authenticate
int Authenticator::authenticate()
{	// first of all a random webpage must be fetched
	int ret;
	char recv_buf[BUF_SIZE + 1]; // the last char is for the string terminator

	memset(&recv_buf, 0, BUF_SIZE + 1); // clear buffer, just in case
	HTTPget(recv_buf, BUF_SIZE, TEST_ADDRESS);
	// if the client is not authenticated then the answer will be:
	// HTTP/1.1 303 See Other
	// read first line and extract status code
	char *codeStr = new char[4];
	strncpy(codeStr, &recv_buf[9], 3);
	codeStr[3] = '\0'; // the string must be null-terminated
	int code = atoi(codeStr);
	if (code == 303)
	{ // authentication needed
		info.hostname = getAuthHost(recv_buf);
		info.magic = getMagicStr(recv_buf);
		ret = doAuth();
	} else
		ret = ALREADY_CONNECTED;

	delete codeStr;
	return ret;
}

// send a get request to refreshURL
void Authenticator::refresh()
{
	char buf[128];		// enough for refreshing
	std::string host, path;

	if (refreshURL.empty())
		throw new InvalidURLException();
	
	std::istringstream iss(refreshURL);
	getline(iss, host, '/');
	getline(iss, path);
	HTTPget(buf, sizeof(buf), host, "/" + path);
}

// Plain old HTTP request with header and stuff
int Authenticator::HTTPget(char* receiveBuffer, size_t bufLength,
		std::string host, std::string path)
{
	std::string request, address, port = "80";
	int ret, sockfd;
	struct addrinfo srvInfo;	// filled by getaddrinfo()
	struct addrinfo *srvInfoLst;

	// extract address and port from host
	std::istringstream iss(host);
	getline(iss, address, ':');
	getline(iss, port);
	// see getaddrinfo() manpage. All unused parameters shall be set to 0
	memset(&srvInfo, 0, sizeof(srvInfo));
	// set socket type & parameters
	srvInfo.ai_family = AF_UNSPEC;     // ipv4 and/or ipv6
	srvInfo.ai_socktype = SOCK_STREAM; // TCP
	ret = getaddrinfo(address.c_str(), port.c_str(), &srvInfo, &srvInfoLst);
	if (ret != 0)
		throw new NetworkException(gai_strerror(ret));
	// ready to create the socket and open the connection
	sockfd = socket(srvInfoLst->ai_family, srvInfoLst->ai_socktype,
			    srvInfoLst->ai_protocol);
	if (sockfd < 0) 
		throw new NetworkException("Could not open socket.");
	ret = connect(sockfd, srvInfoLst->ai_addr, srvInfoLst->ai_addrlen);
	if (ret < 0) 
		throw new NetworkException("Could not setup the connection.");
	// socket opened. Craft the request, send it and listen for incoming data
	request = "GET " + path + " HTTP/1.1\r\n"
	          "Host: " + host + "\r\n"
	          "Connection: close\r\n"
	          "User-Agent: " + USER_AGENT + "\r\n\r\n";
	send(sockfd, request.c_str(), request.length(), 0);
	ret = recv(sockfd, receiveBuffer, bufLength, MSG_WAITALL);
	if (ret < 0)
		throw new NetworkException("Could not receive incoming data.");
	
	freeaddrinfo(srvInfoLst);
	close(sockfd);
	return ret;
}

// Send POST data     
int Authenticator::HTTPpost(char* receiveBuffer, size_t bufLength,
        std::string data, std::string host, std::string path)
{   
	std::string request, address, port = "80";
	int ret, sockfd;
	struct addrinfo srvInfo;	// filled by getaddrinfo()
	struct addrinfo *srvInfoLst;

	// extract address and port from host
	std::istringstream iss(host);
	getline(iss, address, ':');
	getline(iss, port);
	// see getaddrinfo() manpage. All unused parameters shall be set to 0
	memset(&srvInfo, 0, sizeof(srvInfo));
	// set socket type & parameters
	srvInfo.ai_family = AF_UNSPEC;     // ipv4 and/or ipv6
	srvInfo.ai_socktype = SOCK_STREAM; // TCP
	ret = getaddrinfo(address.c_str(), port.c_str(), &srvInfo, &srvInfoLst);
	if (ret != 0)
		throw new NetworkException(gai_strerror(ret));
	// ready to create the socket and open the connection
	sockfd = socket(srvInfoLst->ai_family, srvInfoLst->ai_socktype,
			    srvInfoLst->ai_protocol);
	if (sockfd < 0) 
		throw new NetworkException("Could not open socket.");
	ret = connect(sockfd, srvInfoLst->ai_addr, srvInfoLst->ai_addrlen);
	if (ret < 0) 
		throw new NetworkException("Could not setup the connection.");
	// socket opened craft the request, send it and listen for incoming data
	request = "POST " + path + " HTTP/1.1\r\n"
	          "Host: " + host + "\r\n"
	          "Connection: close\r\n"
	          "User-Agent: " + USER_AGENT + "\r\n"
	          "Content-Length: " + std::to_string(data.length()) + "\r\n"
	          "Content-Type: application/x-www-form-urlencoded\r\n\r\n"
	          + data + "\r\n";
	send(sockfd, request.c_str(), request.length(), 0);
	ret = recv(sockfd, receiveBuffer, bufLength, MSG_WAITALL);
	if (ret < 0)
		throw new NetworkException("Could not receive incoming data.");
	
	freeaddrinfo(srvInfoLst);
	close(sockfd);
	return ret;
}

// alas! a magic token beholds us!
std::string Authenticator::getMagicStr(char* data)
{
	std::string magicStr = "";
	char* startPtr = strchr(data, '?') + 1;
	if (startPtr != 0)
		magicStr.assign(startPtr, 16); // magic string is 16 char long
	return magicStr;
}

// 
std::string Authenticator::getAuthHost(char* data)
{
	const char* hostBegin = "http://";
	std::string host;
	
	char* startPtr = strstr(data, hostBegin) + strlen(hostBegin);
	if (startPtr == 0)
		return "";

	char* endPtr = strchr(startPtr, '/');
	if ((endPtr == 0) || (endPtr < startPtr))
		return "";

	host.assign(startPtr, endPtr - startPtr);

	return host;
}
// send username and password and parse the answer
int Authenticator::doAuth()
{
	char recv_buf[BUF_SIZE + 1]; // receive buffer (last char is for '\0')

	memset(&recv_buf, 0, BUF_SIZE + 1); // clear buffer, just in case
	HTTPget(recv_buf, BUF_SIZE, info.hostname, "/fgtauth?" + info.magic);
	// make the request and receive answer
	std::string dataStr = "username=" + info.username + "&password=" + 
			info.password + "&magic=" + info.magic + "&4Tredir=%2F\r\n";
	memset(&recv_buf, 0, BUF_SIZE);
	HTTPpost(recv_buf, BUF_SIZE, dataStr, info.hostname);
	// determine wether the authentication was successful and if so retrieve
	// the URL to refresh
	char* startPtr = strstr(recv_buf, REFRESH_TOKEN);
	if (startPtr == 0)
		return AUTH_FAIL;
	char* endPtr = strstr(startPtr, "\";"); // javascript close token
	if (endPtr == 0)
		return AUTH_FAIL;
	startPtr += strlen(REFRESH_TOKEN); // take token offset into account
	refreshURL.assign(startPtr, endPtr - startPtr);

	return AUTH_SUCCESS;
}
