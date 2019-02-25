#include "AntiSpiffsWebServer.h"

AntiSpiffsWebServer::AntiSpiffsWebServer(IPAddress addr, int port): WebServerImpl(addr, port) {
	this->notFoundHandlerOrg = 0;
}

AntiSpiffsWebServer::AntiSpiffsWebServer(int port):	WebServerImpl(port) {
	this->notFoundHandlerOrg = 0;
}

void AntiSpiffsWebServer::begin() {
	WebServerImpl::begin();
	initialize();
}

void AntiSpiffsWebServer::begin(uint16_t port) {
	WebServerImpl::begin(port);
	initialize();
}

void AntiSpiffsWebServer::initialize() {
	// запоминаем оригинальный обработчик notFoundHandler
	this->notFoundHandlerOrg = this->_notFoundHandler;
	// Устанавливаем свой обработчик notFoundHandler
	WebServerImpl::onNotFound([this]() {
		// указатель на найденный контент в PROGMEM
		const struct content_info* info = 0;
		if (_currentMethod == HTTP_GET) {  // обрабатываем только GET методы
			// флаг того что нужно искать индекс.хтмл
			bool find_index_html = false;
			if (_currentUri.equals("/")) {	// запросили корень, будем искать индекс
				find_index_html = true;
			}
			// цикл по массиву описателей
			for (size_t n = 0; n < sizeof(_ci) / sizeof(_ci[0]) && info == 0; n++) {
				// если запросили корень и нашли индекс
				if ((find_index_html && strcmp(_ci[n].uri, "/index.html") == 0) ||
						// или нашли запрошенный uri
						strcmp(_ci[n].uri, _currentUri.c_str()) == 0) {
					// сохраняем указатель
					info = &_ci[n];
				}
			}
		}
		if (info != 0) { // если контент нашли, отгружаем его
			// поскольку контент в PROGMEM статика - добавляем заголовок Cache-Control
			sendHeader("Cache-Control", "max-age=86400, public");
			// если контент пережат, добавляем заголовок Content-Encoding
			if (info->gzip) {
				sendHeader("Content-Encoding", "gzip");
			}
			setContentLength(CONTENT_LENGTH_UNKNOWN);
			send(200, info->contentType);
			for (size_t offset = 0; offset < info->size; ) {
				size_t bytes = (info->size - offset) >= CONTENT_BLOCK_MAX ? CONTENT_BLOCK_MAX : info->size - offset;
				sendContent_P(info->content + offset, bytes);
				offset += bytes;
			}
		} else { // если контент не нашли
			if (this->notFoundHandlerOrg) { // вызываем оригинальный обработчик notFoundHandler если он есть
				this->notFoundHandlerOrg();
			} else { // иначе - отвечаем 404-м кодом
				send(404, String(F("text/html")), String(F("Not found: ")) + _currentUri);
			}
		}
	});
}
