#ifndef __AntiSpiffsWebServer_h__
#define __AntiSpiffsWebServer_h__

#include <Arduino.h>
#ifdef ARDUINO_ARCH_ESP8266
#include <ESP8266WebServer.h>
#define WebServerImpl ESP8266WebServer
#elif ARDUINO_ARCH_ESP32
#include <WebServer.h>
#define WebServerImpl WebServer
#else
#error Unsupported architecture, use ARDUINO_ARCH_ESP8266 or ARDUINO_ARCH_ESP32
#endif

#ifndef CONTENT_BLOCK_MAX
#define CONTENT_BLOCK_MAX 2048
#endif

/**
 * Структура, описывающая ассоциации запрашиваемого веб контента и данных расположенных в PROGMEM
 */
struct content_info {

	/**
	 * Указатель на запрашиваемый uri
	 */
	const char* uri;

	/**
	 * Указатель на тип контента
	 */
	const char* contentType;

	/**
	 * Указатель на буфер с контентом в PROGMEM
	 */
	const char* content;

	/**
	 * Количество данных
	 */
	size_t size;

	/**
	 * Признак "сжатых" данных
	 */
	int gzip;
};

#include "memcontent.h"

/**
 * Класс позволяющий отгружать статику расположенную в PROGMEM,
 * класс наследует ESP8266WebServer и добавляет свой обработчик notFound,
 * при вызове метода begin, будет "запомнен" обработчик notFound базового класса и замещён своим обработчиком,
 * если необходимо выполнять в коде свою обработку notFound, выполните onNotFound перед вызовом begin,
 * иначе ваш обработчик не будет вызван.
 */
class AntiSpiffsWebServer: public WebServerImpl {

public:

	/**
	 * Конструктор
	 * @param addr   ip адрес веб сервера
	 * @param port   ip порт веб сервера
	 */
	AntiSpiffsWebServer(IPAddress addr, int port = 80);
	
	/**
	 * Конструктор
	 * @param port   ip порт веб сервера
	 */
	AntiSpiffsWebServer(int port = 80);

	/**
	 * Начать работу веб сервера,
	 * вызывает у базового класса begin() и добавляет свой обработчик notFoundHandler
	 */
	virtual void begin();

	/**
	 * Начать работу веб сервера
	 * @param port   ip порт веб сервера
	 * @see AntiSpiffsWebServer#begin()
	 */
	virtual void begin(uint16_t port);

protected:

	/**
	 * Инициализация обработчика notFoundHandler
	 */
	virtual void initialize();

	/**
	 * Оригинальный обработчик notFoundHandler
	 */
	THandlerFunction notFoundHandlerOrg;
};

#endif
