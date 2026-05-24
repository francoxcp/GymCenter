$R = [char]0xFFFD

# Caracteres correctos
$a  = [char]0x00E1  # a con tilde
$A  = [char]0x00C1  # A con tilde
$e  = [char]0x00E9  # e con tilde
$i  = [char]0x00ED  # i con tilde
$o  = [char]0x00F3  # o con tilde
$u  = [char]0x00FA  # u con tilde
$n  = [char]0x00F1  # enie
$N  = [char]0x00D1  # Enie
$x  = [char]0x00D7  # multiplicacion x
$md = [char]0x00B7  # punto medio (middle dot)
$ar = [char]0x2192  # flecha derecha
$em = [char]0x2014  # raya em dash
$en = [char]0x2013  # raya en dash

$replacements = [ordered]@{
    # Formulas matematicas
    "BMR/1440 $($R) min $($R) MET"   = "BMR/1440 $($x) min $($x) MET"
    "13.397$($R)kg"                   = "13.397$($md)kg"
    "4.799$($R)cm"                    = "4.799$($md)cm"
    "5.677$($R)a$($R)os"             = "5.677$($md)a$($n)os"
    "9.247$($R)kg"                    = "9.247$($md)kg"
    "3.098$($R)cm"                    = "3.098$($md)cm"
    "4.330$($R)a$($R)os"             = "4.330$($md)a$($n)os"
    # Separadores en prosa
    "No bloquea $($R) se"             = "No bloquea $($em) se"
    "cach$($R) $($R) descargar"       = "cach$($e) $($ar) descargar"
    "desc $($R) la primera"           = "desc $($em) la primera"
    # Strings UI (literales Dart)
    "' $($R) `$r'"                    = "' $($x) `$r'"
    "'$($R)'"                         = "'$($en)'"
    # Palabras con o con tilde
    "sesi$($R)n"                      = "sesi$($o)n"
    "Sesi$($R)n"                      = "Sesi$($o)n"
    "navegaci$($R)n"                  = "navegaci$($o)n"
    "hist$($R)rico"                   = "hist$($o)rico"
    "Cron$($R)metro"                  = "Cron$($o)metro"
    "Detecci$($R)n"                   = "Detecci$($o)n"
    "F$($R)rmula"                     = "F$($o)rmula"
    "f$($R)rmula"                     = "f$($o)rmula"
    "cal$($R)rico"                    = "cal$($o)rico"
    "aer$($R)bico"                    = "aer$($o)bico"
    "nataci$($R)n"                    = "nataci$($o)n"
    "Bot$($R)n"                       = "Bot$($o)n"
    "bot$($R)n"                       = "bot$($o)n"
    "animaci$($R)n"                   = "animaci$($o)n"
    "descripci$($R)n"                 = "descripci$($o)n"
    "Descripci$($R)n"                 = "Descripci$($o)n"
    "selecci$($R)n"                   = "selecci$($o)n"
    "Selecci$($R)n"                   = "Selecci$($o)n"
    "opci$($R)n"                      = "opci$($o)n"
    "Opci$($R)n"                      = "Opci$($o)n"
    "acci$($R)n"                      = "acci$($o)n"
    "Acci$($R)n"                      = "Acci$($o)n"
    "notificaci$($R)n"                = "notificaci$($o)n"
    "Notificaci$($R)n"                = "Notificaci$($o)n"
    "configuraci$($R)n"               = "configuraci$($o)n"
    "Configuraci$($R)n"               = "Configuraci$($o)n"
    "informaci$($R)n"                 = "informaci$($o)n"
    "Informaci$($R)n"                 = "Informaci$($o)n"
    "direcci$($R)n"                   = "direcci$($o)n"
    "secci$($R)n"                     = "secci$($o)n"
    "colecci$($R)n"                   = "colecci$($o)n"
    "autorizaci$($R)n"                = "autorizaci$($o)n"
    "aplicaci$($R)n"                  = "aplicaci$($o)n"
    "Aplicaci$($R)n"                  = "Aplicaci$($o)n"
    "versi$($R)n"                     = "versi$($o)n"
    "Versi$($R)n"                     = "Versi$($o)n"
    "relaci$($R)n"                    = "relaci$($o)n"
    "condici$($R)n"                   = "condici$($o)n"
    "Condici$($R)n"                   = "Condici$($o)n"
    "soluci$($R)n"                    = "soluci$($o)n"
    "eliminaci$($R)n"                 = "eliminaci$($o)n"
    "Eliminaci$($R)n"                 = "Eliminaci$($o)n"
    "cancelaci$($R)n"                 = "cancelaci$($o)n"
    "realizaci$($R)n"                 = "realizaci$($o)n"
    "asociaci$($R)n"                  = "asociaci$($o)n"
    "evaluaci$($R)n"                  = "evaluaci$($o)n"
    "actualizaci$($R)n"               = "actualizaci$($o)n"
    "Actualizaci$($R)n"               = "Actualizaci$($o)n"
    "protecci$($R)n"                  = "protecci$($o)n"
    "recopilaci$($R)n"               = "recopilaci$($o)n"
    "conservaci$($R)n"                = "conservaci$($o)n"
    "comunicaci$($R)n"                = "comunicaci$($o)n"
    "utilizaci$($R)n"                 = "utilizaci$($o)n"
    "transformaci$($R)n"              = "transformaci$($o)n"
    "personalizaci$($R)n"             = "personalizaci$($o)n"
    "ubicaci$($R)n"                   = "ubicaci$($o)n"
    "restricci$($R)n"                 = "restricci$($o)n"
    "compensaci$($R)n"                = "compensaci$($o)n"
    "colaboraci$($R)n"                = "colaboraci$($o)n"
    "subscripci$($R)n"                = "subscripci$($o)n"
    "sincronizaci$($R)n"              = "sincronizaci$($o)n"
    "publicaci$($R)n"                 = "publicaci$($o)n"
    "presentaci$($R)n"                = "presentaci$($o)n"
    "continuaci$($R)n"                = "continuaci$($o)n"
    "resoluci$($R)n"                  = "resoluci$($o)n"
    "interacci$($R)n"                 = "interacci$($o)n"
    "integraci$($R)n"                 = "integraci$($o)n"
    "generaci$($R)n"                  = "generaci$($o)n"
    "funci$($R)n"                     = "funci$($o)n"
    "Funci$($R)n"                     = "Funci$($o)n"
    # mas palabras con o con tilde
    "c$($R)mo"                        = "c$($o)mo"
    "C$($R)mo"                        = "C$($o)mo"
    "conocimiento"                    = "conocimiento"
    "proporci$($R)n"                  = "proporci$($o)n"
    "m$($R)vil"                       = "m$($o)vil"
    "M$($R)vil"                       = "M$($o)vil"
    "ser$($R)"                        = "ser$($o)"
    # Palabras con a con tilde
    "C$($R)lculo"                     = "C$($a)lculo"
    "c$($R)lculo"                     = "c$($a)lculo"
    "calor$($R)as"                    = "calor$($i)as"
    "autom$($R)ticamente"            = "autom$($a)ticamente"
    "di$($R)logo"                     = "di$($a)logo"
    "Di$($R)logo"                     = "Di$($a)logo"
    "m$($R)ximo"                      = "m$($a)ximo"
    "M$($R)ximo"                      = "M$($a)ximo"
    "No est$($R)"                     = "No est$($a)"
    "est$($R) "                       = "est$($a) "
    "est$($R)s"                       = "est$($a)s"
    "tambi$($R)n"                     = "tambi$($e)n"
    "Tambi$($R)n"                     = "Tambi$($e)n"
    "pr$($R)ctica"                    = "pr$($a)ctica"
    "Pr$($R)ctica"                    = "Pr$($a)ctica"
    "caracter$($R)stica"              = "caracter$($i)stica"
    "estad$($R)stica"                 = "estad$($i)stica"
    "f$($R)sica"                      = "f$($i)sica"
    "F$($R)sica"                      = "F$($i)sica"
    "gr$($R)fica"                     = "gr$($a)fica"
    "Gr$($R)fica"                     = "Gr$($a)fica"
    "p$($R)gina"                      = "p$($a)gina"
    "P$($R)gina"                      = "P$($a)gina"
    "f$($R)cil"                       = "f$($a)cil"
    "F$($R)cil"                       = "F$($a)cil"
    "cl$($R)usula"                    = "cl$($a)usula"
    "p$($R)rrafo"                     = "p$($a)rrafo"
    "p$($R)rr"                        = "p$($a)rr"
    "c$($R)mara"                      = "c$($a)mara"
    "C$($R)mara"                      = "C$($a)mara"
    "p$($R)rdida"                     = "p$($e)rdida"
    "p$($R)rdid"                      = "p$($e)rdid"
    "t$($R)rmino"                     = "t$($e)rmino"
    "T$($R)rmino"                     = "T$($e)rmino"
    "acad$($R)mico"                   = "acad$($e)mico"
    "m$($R)dico"                      = "m$($e)dico"
    "M$($R)dico"                      = "M$($e)dico"
    # Palabras con e con tilde
    "cach$($R)"                       = "cach$($e)"
    "despu$($R)s"                     = "despu$($e)s"
    # Palabras con i con tilde
    "d$($R)a"                         = "d$($i)a"
    "l$($R)neas"                      = "l$($i)neas"
    "el$($R)ptica"                    = "el$($i)ptica"
    "n$($R)mero"                      = "n$($u)mero"
    "N$($R)mero"                      = "N$($u)mero"
    "n$($R)meros"                     = "n$($u)meros"
    "p$($R)blico"                     = "p$($u)blico"
    "P$($R)blico"                     = "P$($u)blico"
    # Palabras con u con tilde
    "$($R)ltimos"                     = "$($u)ltimos"
    "$($R)ltimas"                     = "$($u)ltimas"
    "$($R)ltimo"                      = "$($u)ltimo"
    "$($R)ltima"                      = "$($u)ltima"
    "$($R)ltim"                       = "$($u)ltim"
    "m$($R)ltiples"                   = "m$($u)ltiples"
    "m$($R)ltiple"                    = "m$($u)ltiple"
    # Palabras con enie
    "se$($R)ales"                     = "se$($n)ales"
    "se$($R)al"                       = "se$($n)al"
    "Se$($R)al"                       = "Se$($n)al"
    "Espa$($R)ol"                     = "Espa$($n)ol"
    "espa$($R)ol"                     = "espa$($n)ol"
    "a$($R)os"                        = "a$($n)os"
    "A$($R)os"                        = "A$($n)os"
    "compa$($R)ero"                   = "compa$($n)ero"
    "da$($R)o"                        = "da$($n)o"
    # mas con a
    "m$($R)s"                         = "m$($a)s"
    "M$($R)s"                         = "M$($a)s"
    "dem$($R)s"                       = "dem$($a)s"
    # Restantes genericos
    "prop$($R)sito"                   = "prop$($o)sito"
    "Prop$($R)sito"                   = "Prop$($o)sito"
    "b$($R)squeda"                    = "b$($u)squeda"
    "B$($R)squeda"                    = "B$($u)squeda"
    "cre$($R)n"                       = "cre$($o)n"
    "garant$($R)a"                    = "garant$($i)a"
    "pol$($R)tica"                    = "pol$($i)tica"
    "Pol$($R)tica"                    = "Pol$($i)tica"
    "acuerdos"                        = "acuerdos"
    "afiliaci$($R)n"                  = "afiliaci$($o)n"
    "correcci$($R)n"                  = "correcci$($o)n"
    "tr$($R)mite"                     = "tr$($a)mite"
    "p$($R)rdida"                     = "p$($e)rdida"
    "cl$($R)usula"                    = "cl$($a)usula"
    "advertencia"                     = "advertencia"
}

$files = Get-ChildItem -Path "d:\ChamosFitnessCenter\lib" -Recurse -Filter "*.dart"
$totalFixed = 0

foreach ($file in $files) {
    $content = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    $hasFFD = ($content.ToCharArray() | Where-Object { [int]$_ -eq 0xFFFD }).Count
    if ($hasFFD -eq 0) { continue }

    $original = $content
    foreach ($pair in $replacements.GetEnumerator()) {
        $content = $content.Replace($pair.Key, $pair.Value)
    }

    $remaining = ($content.ToCharArray() | Where-Object { [int]$_ -eq 0xFFFD }).Count
    [IO.File]::WriteAllText($file.FullName, $content, [Text.Encoding]::UTF8)
    Write-Host "OK: $($file.Name) (FFFD antes=$hasFFD, despues=$remaining)"
    $totalFixed++
}

Write-Host ""
Write-Host "Total archivos procesados: $totalFixed"
