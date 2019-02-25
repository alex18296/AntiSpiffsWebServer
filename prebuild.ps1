$build_path=$args[0]
$project_name=$args[1]

# Строка - возврат каретки & перевод строки
[string]$crlf = "`r`n"

# Функция сжатия данных gzip
function ConvertTo-GzipData {
  [cmdletBinding()]
  param(
    [parameter(Mandatory = $true, ValueFromPipeline = $false)]
    [byte[]]$Data
  )
  Process {
    $output = [System.IO.MemoryStream]::new()
    $gzipStream = New-Object System.IO.Compression.GzipStream $output, ([IO.Compression.CompressionMode]::Compress)
    $gzipStream.Write($Data, 0, $Data.Length)
    $gzipStream.Close()
    return $output.ToArray()
  }
}

# Функция получения списка файлов
function GetFiles($path, [string[]]$exclude) { 
  foreach ($item in Get-ChildItem $path) {
    if ($exclude | Where {$item -like $_}) {
      continue
    }
    if (Test-Path $item.FullName -PathType Container) {
      GetFiles $item.FullName $exclude
    } else { 
      $item
    }
  } 
}

# Определим словарь типов контента
$contentTypes = @{}
$contentTypes += @{'.html' = 'text/html'}
$contentTypes += @{'.htm' = 'text/html'}
$contentTypes += @{'.js' = 'application/javascript'}
$contentTypes += @{'.css' = 'text/css'}
$contentTypes += @{'.json' = 'application/json'}
$contentTypes += @{'.text' = 'text/plain'}
$contentTypes += @{'.txt' = 'text/plain'}
$contentTypes += @{'.ico' = 'image/x-icon'}
$contentTypes += @{'.png' = 'image/png'}
$contentTypes += @{'.gif' = 'image/gif'}
$contentTypes += @{'.jpeg' = 'image/jpeg'}
$contentTypes += @{'.jpg' = 'image/jpeg'}
$contentTypes += @{'.svg' = 'image/svg+xml'}

# Установим имя файла исходника для сохранения
$memcontent='memcontent.h'
# Определяем переменную для хранения контента
[string]$content

# Определим массивы для хранения
# имени запрашиваемого url
[string[]]$names = @()
# имени соответствующей переменной в PROGMEM
[string[]]$tags = @()
# типа контента
[string[]]$types = @()
# признака сжатого контента
[int[]]$zips = @()

# Устанавливаем минимальный размер файла для передачи без сжатия
[int]$min_size=2000

# Удаляем прежний memcontent.h
if([System.IO.File]::Exists($memcontent)) {
  Remove-Item $memcontent
}
# Определим флаг, что индекс.хтмл не найден
[bool]$index_file_found=$false

# Сохраняем дату генерации файла
$content = '// File generated date: ' + $(Get-Date).ToString('ddd, dd MMM yyyy HH:mm:ss') + $crlf

# Получаем список файлов
$dir_list = GetFiles '.\\data' xyz | % { $_.fullname }
# Поскольку строки с именами файлов содержат полный путь, установим смещение для получения относительного пути
[int]$start = ([string]$pwd).Length + 6

# Обрабатываем полученный список файлов
foreach ($file_name in $dir_list) {
  # Получаем длину файла
  [int]$file_size=(Get-Item $file_name).Length

  Write-Host 'Converting:' $file_name.Substring($start)

  if ($file_size -gt 0) {
    # Удаляем из имени файла название директории './data'
    [string]$req_name=$file_name.Substring($start)
    
    # Если файл индекс.хтмл - установим флаг в true
    if ($req_name.Equals('index.html')) {
      $index_file_found=$true
    }
    
    # Выделяем расширение файла
    [string]$ext=[System.IO.Path]::GetExtension($file_name)
    
    # Заменяем в имени '\' на '/', как в http запросах
    $req_name=$req_name.Replace('\','/')

    # Строим название переменной для PROGMEM из имени файла, заменяем спец. символы в имени на '_'
    [string]$tag='_'+$req_name.Replace('/','_').Replace('.','_').Replace('-','_').Replace('[','_').Replace(']','_')

    # Вычисляем тип контента
    [string]$c_type=$contentTypes.Item($ext)
    if ([string]::IsNullOrEmpty($c_type)) {
      $c_type='application/octet-stream'
      Write-Host  'Warning: content type is not detected for file'$file_name.Substring($start)', set as'$c_type
    }

    # Загружаем файл
    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($file_name)
    
    # Если длина файла больше или равна установленному минимальному значению, сжимаем его
    if ($file_size -ge $min_size) {
      $zips+=(1)
      $bytes = ConvertTo-GzipData -Data $bytes
    } else {
      $zips+=(0)
    }

    # Сохраняем декларацию масива байтов
    $content += $crlf
    $content += '//############ ' + $req_name + ' ############' + $crlf
    $content += 'static unsigned char ' + $tag +'[] PROGMEM = {' + $crlf

    # Сохраняем шестнадцатиричное представление масива байтов
    $hexBuilder = [System.Text.StringBuilder]::new(16 * 6)
    for($i=0; $i -lt $bytes.Length; ) {
      if (($i + 1) -lt $bytes.Length) {
        $hexBuilder.AppendFormat("0x{0:x2},", $bytes[$i]) | Out-Null
      } else {
        $hexBuilder.AppendFormat("0x{0:x2}", $bytes[$i]) | Out-Null
      }
      $i++
      if (($i % 16) -eq 0) {
        $content += $hexBuilder.ToString() + $crlf
        $hexBuilder = [System.Text.StringBuilder]::new(16 * 6)
      }
    }
    $content += $hexBuilder.ToString() + '};' + $crlf

    # Запоминаем имя запрашиваемого url
    $names+=($req_name)
    # Запоминаем имя соответствующей переменной в PROGMEM
    $tags+=($tag)
    # Запоминаем типа контента
    $types+=($c_type)
  } else {
    Write-Host 'Warning: file'$req_name'is empty, ignored this file'
  }
}

if ( !$index_file_found ) {
  Write-Host Warning: index.html not found
}

if ($names.Count -gt 0) {
  # Сохраняем структуру, описывающую переменные, которые мы построили в PROGMEM
  $content += $crlf
  $content += 'static struct content_info _ci['+ $names.Count +'] PROGMEM = {' + $crlf
  for($i=0; $i -lt $names.Count; ) {
    $content += '  {"/'+$names[$i]+'", "'+$types[$i]+'", (const char*)'+$tags[$i]+', sizeof('+$tags[$i]+'), '+$zips[$i]+'}'
    $i++
    if ($i -lt $names.Count) {
      $content += ','
    }
    $content += $crlf
  }
  $content += '};' + $crlf

  # Сохраняем файл
  Set-Content -Path $memcontent -Value $content

  # Копируем файл в директорию для билда
  if ( ![string]::IsNullOrEmpty($build_path)) {
    $memcontent = $build_path+'\\sketch\\'+$memcontent
    if([System.IO.File]::Exists($memcontent)) {
      Remove-Item $memcontent
    }
    Set-Content -Path $memcontent -Value $content

    # Меняем YourRouterSSID & YourRouterPassword в оригинальном скетче
    if ( ![string]::IsNullOrEmpty($project_name)) {
      [string]$wifi_ssid = [System.Environment]::GetEnvironmentVariable("WIFI_SSID", "User")
      [string]$wifi_password = [System.Environment]::GetEnvironmentVariable("WIFI_PASSWORD", "User")
      if ( ![string]::IsNullOrEmpty($wifi_ssid)) {
        [string]$sketch_file = $build_path+'\\sketch\\'+$project_name+'.cpp'
        Write-Host 'Changing YourRouterSSID & YourRouterPassword in'$sketch_file
        $data = Get-Content $project_name
        $data = $data.Replace('YourRouterSSID', $wifi_ssid).Replace('YourRouterPassword', $wifi_password)
        Set-Content -Path $sketch_file -Value $data
      }
    }
  }
} else {
  Write-Host Error: no data for storage
}
