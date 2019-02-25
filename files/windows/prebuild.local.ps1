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
