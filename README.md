Добавлять статику (страницы, стили, скрипты, изображения) в исходный код и править этот код очень не удобно.  
Можно сохранять статику в директорию data и загружать на spiffs используя arduino-esp8266fs-plugin, но загрузка длится вечность, кроме этого, можно просто забыть её загрузить.  
По этому была сделана простая обёртка над классом ESP8266WebServer (для esp8266) или WebServer (для esp32) для отгрузки статики расположенной в PROGMEM.

##### Требования к системе
- [Среда разработки: arduino ide 1.8.8](https://www.arduino.cc/en/Main/Software)  
- [Поддержка esp8266: ESP8266 core for Arduino 2.5.0](https://github.com/esp8266/Arduino)  
- [Поддержка esp32: Arduino core for the ESP32 1.0.1](https://github.com/espressif/arduino-esp32)  
  
Указаны версии ПО на которых выполнялась проверка

Вся статика от веб-интерфейса как и в примере FSBrowser находится в директории data, но не загружается отдельно, а преобразуется "налету" в файл memcontent.h во время сборки, попадая в массивы байтов с атрибутом PROGMEM.  
Преобразование выполняется в prebuild (prebuild.ps1 для windows), кроме этого, также "налету" выполняется замена в оригинальном скетче идентификатора и пароля точки доступа wifi, порой бывает полезно, когда делишься проектом и не хочешь светить пароли. 
  
Для автоматического выполнения дополнительных скриптов во время сборки, в директории hardware соответствующей архитектуры, рядышком с файлом platform.txt создаем файл platform.local.txt
 
```
recipe.hooks.sketch.prebuild.0.pattern = {runtime.platform.path}/prebuild.local {build.source.path} {build.path} {build.project_name}
```
Для Windows
 
```
recipe.hooks.sketch.prebuild.0.pattern = powershell.exe -file {runtime.platform.path}\prebuild.local.ps1 {build.source.path} {build.path} {build.project_name}
```
 
Там же создаем prebuild.local

```
#!/bin/bash
# проверяем наличие файла prebuild в исходной директории со скетчем
if [ -e "$1/prebuild" ]
then
  # переходим в исходную директорию со скетчем
  cd $1
  # выполняем prebuild передавая путь ко временной директории созданной ардуиной для билда и название проекта
  ./prebuild $2 $3
fi
```
Для Windows создаем prebuild.local.ps1

```
$source_path = $args[0]
$build_path = $args[1]
$project_name = $args[2]

$prebuild_file = 'prebuild.ps1'
$prebuild_path = $source_path + '\\' + $prebuild_file

if (Test-Path $prebuild_path) {
  pushd
  cd $source_path
  powershell.exe -file $prebuild_file $build_path $project_name
  popd
}
```
