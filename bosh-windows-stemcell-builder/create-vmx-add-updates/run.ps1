cd stemcell-builder
bundle install
if ($LASTEXITCODE -ne 0) {
  Write-Error "Could not bundle install"
  Exit 1
}
rake package:psmodules
if ($LASTEXITCODE -ne 0) {
  Write-Error "Could not package psmodules"
  Exit 1
}
rake build:vsphere_add_updates
if ($LASTEXITCODE -ne 0) {
  Write-Error "Could not install updates to vsphere image"
  Exit 1
}
