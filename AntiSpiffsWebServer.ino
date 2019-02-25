#ifdef ARDUINO_ARCH_ESP8266
#include <ESP8266WiFi.h>
#elif ARDUINO_ARCH_ESP32
#include <WiFi.h>
#endif

//#define SSID      "YourRouterSSID"
//#define PASSWORD  "YourRouterPassword"

#include "AntiSpiffsWebServer.h"

// Веб сервер
AntiSpiffsWebServer _server;

// Фейковый конфиг, который ничего не делает.
String _config = "{\"chk1\":\"yes\",\"str1\":\"abcdef\",\"music\":\"\",\"r\":\"128\",\"g\":\"128\",\"b\":\"128\"}";

// Журнал
#define JOURNAL_SIZE	10
String _journal[JOURNAL_SIZE];
int _journal_record = 0;

void to_journal(const String& message) {
	char tmp[8];
	sprintf(tmp, "%d", _journal_record);
	_journal[_journal_record % JOURNAL_SIZE] = String(F("{\"n\":")) + tmp + String(F(",\"l\":\"")) + message + String(F("\"}"));
	_journal_record++;
}

void setup() {
	Serial.begin(115200);
	Serial.println();
	Serial.println();

	// Инициализируем wifi
	WiFi.persistent(false);
	WiFi.mode(WIFI_OFF);
	delay(100);
	WiFi.mode(WIFI_AP);
	WiFi.softAP("ESP-Test");

	char tmp[64];
#ifdef ARDUINO_ARCH_ESP8266
	uint32_t id = ESP.getChipId();
	sprintf(tmp, "Module ESP8266 with id: %08X, started", id);
#elif ARDUINO_ARCH_ESP32
	uint32_t id_h = (uint32_t)(ESP.getEfuseMac() >> 32);
	uint32_t id_l = (uint32_t)(ESP.getEfuseMac());
	sprintf(tmp, "Module ESP32 with id: %08X%08X, started", id_h, id_l);
#endif
	to_journal(String(tmp));

	// Добавляем обработчик для запроса статуса
	_server.on("/state", HTTP_GET, []() {
		char tmp[16];
		sprintf(tmp, "%d", ESP.getFreeHeap());
		String s = String(F("{\"heap\":")) + tmp + String(F(",\"journal\":["));
		int pos = _journal_record < JOURNAL_SIZE ? 0 : (_journal_record - JOURNAL_SIZE) % JOURNAL_SIZE;
		for (int n = 0; n < JOURNAL_SIZE && _journal[pos % JOURNAL_SIZE].length() > 0; n++, pos++) {
			if (n != 0) {
				s += ',';
			}
			s += _journal[pos % JOURNAL_SIZE];
		}
		s += "]}";
		_server.send(200, "text/json", s);
	});

	// Добавляем обработчик для запроса конфигурационных параметров
	_server.on("/config", HTTP_GET, []() {
		// Возвращаем значение конфига
		_server.send(200, "text/json", _config);
	});

	// Добавляем обработчик для обновления конфигурационных параметров
	_server.on("/config", HTTP_POST, []() {
		// Получаем строку json с новым конфигом
		String s = _server.arg("plain");
		// Если что то получили и оно отличное от прежнего конфига, считаем что данные корректные и не проверяем их, просто обновляем текущий конфиг
		if (s.length() > 0 && _config.equals(s) == false) {
			_config = s;
			s.replace('{', ' ');
			s.replace('}', ' ');
			s.replace('"', ' ');
			to_journal(String(F("Configuration updated.")) + s);
		}
		_server.send(200, "text/json", "{\"rc\":\"OK\"}");
	});

	// Добавляем обработчик на остальные запросы
	_server.onNotFound([]() {
		_server.send(404, String(F("text/html")), String(F("Page not found")));
	});

	// Стартуем сервер
	_server.begin(80);
}

void loop() {
	_server.handleClient();
}
