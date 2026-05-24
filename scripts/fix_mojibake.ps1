$R = [char]0xFFFD

$replacements = [ordered]@{
    "BMR/1440 $($R) min $($R) MET" = "BMR/1440 x min x MET"
    "13.397$($R)kg" = "13.397*kg"
    "4.799$($R)cm" = "4.799*cm"
    "5.677$($R)a$($R)os" = "5.677*anos"
    "9.247$($R)kg" = "9.247*kg"
    "3.098$($R)cm" = "3.098*cm"
    "4.330$($R)a$($R)os" = "4.330*anos"
    "No bloquea $($R) se" = "No bloquea - se"
    "cach$($R) $($R) descargar" = "cache -> descargar"
    "desc $($R) la primera" = "desc - la primera"
    "' $($R) `$r'" = "' x `$r'"
    "'$($R)'" = "'-'"
    "sesi$($R)n" = "sesion"
    "navegaci$($R)n" = "navegacion"
    "hist$($R)rico" = "historico"
    "Cron$($R)metro" = "Cronometro"
    "Detecci$($R)n" = "Deteccion"
    "F$($R)rmula" = "Formula"
    "f$($R)rmula" = "formula"
    "cal$($R)rico" = "calorico"
    "aer$($R)bico" = "aerobico"
    "nataci$($R)n" = "natacion"
    "Bot$($R)n" = "Boton"
    "bot$($R)n" = "boton"
    "animaci$($R)n" = "animacion"
    "descripci$($R)n" = "descripcion"
    "Descripci$($R)n" = "Descripcion"
    "selecci$($R)n" = "seleccion"
    "Selecci$($R)n" = "Seleccion"
    "opci$($R)n" = "opcion"
    "Opci$($R)n" = "Opcion"
    "acci$($R)n" = "accion"
    "Acci$($R)n" = "Accion"
    "notificaci$($R)n" = "notificacion"
    "Notificaci$($R)n" = "Notificacion"
    "configuraci$($R)n" = "configuracion"
    "Configuraci$($R)n" = "Configuracion"
    "informaci$($R)n" = "informacion"
    "Informaci$($R)n" = "Informacion"
    "direcci$($R)n" = "direccion"
    "secci$($R)n" = "seccion"
    "colecci$($R)n" = "coleccion"
    "autorizaci$($R)n" = "autorizacion"
    "aplicaci$($R)n" = "aplicacion"
    "Aplicaci$($R)n" = "Aplicacion"
    "versi$($R)n" = "version"
    "Versi$($R)n" = "Version"
    "C$($R)lculo" = "Calculo"
    "c$($R)lculo" = "calculo"
    "calor$($R)as" = "calorias"
    "autom$($R)ticamente" = "automaticamente"
    "di$($R)logo" = "dialogo"
    "Di$($R)logo" = "Dialogo"
    "m$($R)ximo" = "maximo"
    "M$($R)ximo" = "Maximo"
    "No est$($R)" = "No esta"
    "est$($R) " = "esta "
    "est$($R)s" = "estas"
    "tambi$($R)n" = "tambien"
    "Tambi$($R)n" = "Tambien"
    "cach$($R)" = "cache"
    "despu$($R)s" = "despues"
    "d$($R)a" = "dia"
    "l$($R)neas" = "lineas"
    "el$($R)ptica" = "eliptica"
    "n$($R)mero" = "numero"
    "N$($R)mero" = "Numero"
    "n$($R)meros" = "numeros"
    "$($R)ltimos" = "ultimos"
    "$($R)ltimas" = "ultimas"
    "$($R)ltimo" = "ultimo"
    "$($R)ltima" = "ultima"
    "$($R)ltim" = "ultim"
    "m$($R)ltiples" = "multiples"
    "m$($R)ltiple" = "multiple"
    "se$($R)ales" = "senales"
    "se$($R)al" = "senal"
    "Se$($R)al" = "Senal"
    "Espa$($R)ol" = "Espanol"
    "espa$($R)ol" = "espanol"
    "a$($R)os" = "anos"
    "A$($R)os" = "Anos"
    "m$($R)s" = "mas"
    "M$($R)s" = "Mas"
}

$files = Get-ChildItem -Path "d:\ChamosFitnessCenter\lib" -Recurse -Filter "*.dart"
$totalFixed = 0

foreach ($file in $files) {
    $content = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    $hasFFFD = $content.ToCharArray() | Where-Object { [int]$_ -eq 0xFFFD }
    if (-not $hasFFFD) { continue }

    $original = $content
    foreach ($pair in $replacements.GetEnumerator()) {
        $content = $content.Replace($pair.Key, $pair.Value)
    }

    $remainingCount = ($content.ToCharArray() | Where-Object { [int]$_ -eq 0xFFFD }).Count
    [IO.File]::WriteAllText($file.FullName, $content, [Text.Encoding]::UTF8)
    Write-Host "Corregido: $($file.Name) (FFFD restantes: $remainingCount)"
    $totalFixed++
}

Write-Host ""
Write-Host "Total archivos procesados: $totalFixed"
