#include <iostream>
#include <string>
#include <unistd.h>
#include <ctime>

#include "authenticator.h"

/*
 * Time interval between two different refreshes of the 'keepalive window'
 */
#define REFRESH_TIME (15 * 60)	// seconds

int main(int argc, char *argv[])
{
	std::string username = "scarampdm16";
	std::string password = "pol.scr4";
	time_t now = time(0);
	std::cout <<ctime(&now) <<" > Fortia started.\n";
	// parse config file

	// authenticate
	Authenticator *auth = new Authenticator(username, password);

	int ret = auth->authenticate();
	switch (ret) {
		case Authenticator::AUTH_SUCCESS:
			std::cout <<"Succesfully authenticated with " <<username <<'\n';
			break;
		case Authenticator::AUTH_FAIL:
			std::cout <<"Wrong username and/or password for " <<username <<'\n';
			delete auth;
			return -1;
		case Authenticator::ALREADY_CONNECTED:
			std::cout <<"Everything hunky-dory. You are already connected.\n";
			delete auth;
			return 0;
		default:
			std::cout <<"Unexpected return value: " <<ret <<'\n';
			delete auth;
			return -1;
	}
	// if we get here then ret == Authenticator::AUTH_SUCCESS
	// Refresh the webpage if still authenticated.
	// Otherwhise authenticate again
	while (1) {
		int ret = auth->authenticate();
		
		if (ret == Authenticator::ALREADY_CONNECTED)
			auth->refresh();
		else {	// TODO: use proper logging facility
			time_t now = time(0);
			std::cout <<ctime(&now) <<" > Reauthenticated.\n";
			std::cout.flush();
		}
		sleep(REFRESH_TIME);
	}

	delete auth;
	return 0;
}
