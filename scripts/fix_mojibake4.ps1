$R  = [char]0xFFFD
$a  = [char]0x00E1; $A  = [char]0x00C1; $e  = [char]0x00E9; $E2 = [char]0x00C9
$i  = [char]0x00ED; $I2 = [char]0x00CD; $o  = [char]0x00F3; $O2 = [char]0x00D3
$u  = [char]0x00FA; $U2 = [char]0x00DA; $n  = [char]0x00F1; $N2 = [char]0x00D1
$x  = [char]0x00D7; $md = [char]0x00B7; $ar = [char]0x2192
$em = [char]0x2014; $en = [char]0x2013; $bu = [char]0x2022

# PASS 1: FFFD restantes
$pairs = @(
    # Puntos de bala (bullet points)
    ,@("'$($R) ",                          "'$($bu) ")
    ,@("`n$($R) ",                         "`n$($bu) ")
    ,@("`n`n$($R) ",                       "`n`n$($bu) ")
    # Palabras con ? → o
    ,@("pr$($R)ximo",                      "pr$($o)ximo")
    ,@("pr$($R)xima",                      "pr$($o)xima")
    ,@("pr$($R)ximas",                     "pr$($o)ximas")
    ,@("Pr$($R)ximo",                      "Pr$($o)ximo")
    ,@("Pr$($R)xima",                      "Pr$($o)xima")
    ,@("encontr$($R)",                     "encontr$($o)")
    ,@("actualiz$($R)",                    "actualiz$($o)")
    ,@("complet$($R)",                     "complet$($o)")
    ,@("seg$($R)n",                        "seg$($u)n")
    # Palabras con ? → a
    ,@("est$($R)n",                        "est$($a)n")
    ,@("instant$($R)neo",                  "instant$($a)neo")
    ,@("ser$($R) ",                        "ser$($a) ")
    ,@("estar$($R)",                       "estar$($a)")
    ,@("dar$($R)",                         "dar$($a)")
    ,@("har$($R)",                         "har$($a)")
    # Palabras con ? → i
    ,@("$($R)ndice",                       "$($i)ndice")
    ,@("$($R)ndices",                      "$($i)ndices")
    ,@("$($R)nico",                        "$($u)nico")
    ,@("$($R)nica",                        "$($u)nica")
    ,@("$($R)nicamente",                   "$($u)nicamente")
    ,@("D$($R)a",                          "D$($i)a")
    ,@("categor$($R)a",                    "categor$($i)a")
    ,@("exist$($R)a",                      "exist$($i)a")
    ,@("electr$($R)nico",                  "electr$($o)nico")
    ,@("electr$($R)nicos",                 "electr$($o)nicos")
    ,@("f$($R)sico",                       "f$($i)sico")
    ,@("F$($R)sico",                       "F$($i)sico")
    ,@("b$($R)ceps",                       "b$($i)ceps")
    ,@("B$($R)ceps",                       "B$($i)ceps")
    ,@("hu$($R)rfanos",                    "hu$($e)rfanos")
    ,@("qu$($R) ",                         "qu$($e) ")
    ,@("contrase$($R)a",                   "contrase$($n)a")
    ,@("contrase$($R)as",                  "contrase$($n)as")
    ,@("fotograf$($R)as",                  "fotograf$($i)as")
    ,@("fotograf$($R)a",                   "fotograf$($i)a")
    ,@("Retenci$($R)n",                    "Retenci$($o)n")
    ,@("tr$($R)nsito",                     "tr$($a)nsito")
    ,@("Auditor$($R)as",                   "Auditor$($i)as")
    ,@("auditor$($R)as",                   "auditor$($i)as")
    ,@("tecnolog$($R)as",                  "tecnolog$($i)as")
    ,@("tecnolog$($R)a",                   "tecnolog$($i)a")
    ,@("expl$($R)cito",                    "expl$($i)cito")
    ,@("expl$($R)cita",                    "expl$($i)cita")
    ,@("plazo",                            "plazo")
    ,@("precisi$($R)n",                    "precisi$($o)n")
    ,@("Precisi$($R)n",                    "Precisi$($o)n")
    ,@("espec$($R)ficos",                  "espec$($i)ficos")
    ,@("espec$($R)ficas",                  "espec$($i)ficas")
    ,@("espec$($R)fico",                   "espec$($i)fico")
    ,@("espec$($R)fica",                   "espec$($i)fica")
    ,@("m$($R)s",                          "m$($a)s")
    ,@("M$($R)s",                          "M$($a)s")
    ,@("Rectificaci$($R)n",               "Rectificaci$($o)n")
    ,@("Revocaci$($R)n",                   "Revocaci$($o)n")
    ,@("obligaciones",                     "obligaciones")
    ,@("t$($R)cnicas",                     "t$($e)cnicas")
    ,@("T$($R)cnicas",                     "T$($e)cnicas")
    ,@("org$($R)nicas",                    "org$($a)nicas")
    ,@("Org$($R)nica",                     "Org$($a)nica")
    ,@("p$($R)rdida",                      "p$($e)rdida")
    ,@("P$($R)rdida",                      "P$($e)rdida")
    ,@("Interrupci$($R)n",                 "Interrupci$($o)n")
    ,@("Limitaci$($R)n",                   "Limitaci$($o)n")
    ,@("Cancelaci$($R)n",                  "Cancelaci$($o)n")
    ,@("variaci$($R)n",                    "variaci$($o)n")
    ,@("lesiones",                         "lesiones")
    ,@("responsabilidad",                  "responsabilidad")
    ,@("actualizaciones",                  "actualizaciones")
    ,@("servicios",                        "servicios")
    ,@("acuerdos",                         "acuerdos")
    ,@("propiedad",                        "propiedad")
    ,@("plataforma",                       "plataforma")
    ,@("compromete",                       "compromete")
    ,@("resultados",                       "resultados")
    ,@("ejercicios",                       "ejercicios")
    ,@("actividades",                      "actividades")
    ,@("contenido",                        "contenido")
    ,@("momento",                          "momento")
    ,@("cuenta",                           "cuenta")
    ,@("desde",                            "desde")
    # home_screen
    ,@("// 1$($R)$($R) ",                  "// 1. ")
    ,@("pr$($R)ximamente",                 "pr$($o)ximamente")
    # Remaining
    ,@("$($R)",                            "?")
)

# PASS 2: corregir letras mayusculas acentuadas que deben ser minusculas
$ucPairs = @(
    # sesiÓn → sesión (patrón: consonantes+Ó+n en posicion de sílaba final)
    ,@("sesi$($O2)n",    "sesi$($o)n")
    ,@("Sesi$($O2)n",    "Sesi$($o)n")
    ,@("funci$($O2)n",   "funci$($o)n")
    ,@("Funci$($O2)n",   "Funci$($o)n")
    ,@("informaci$($O2)n","informaci$($o)n")
    ,@("Informaci$($O2)n","Informaci$($o)n")
    ,@("actualizaci$($O2)n","actualizaci$($o)n")
    ,@("ActualizaciÓn",  "Actualizaci$($o)n")
    ,@("aplicaci$($O2)n","aplicaci$($o)n")
    ,@("Aplicaci$($O2)n","Aplicaci$($o)n")
    ,@("configuraci$($O2)n","configuraci$($o)n")
    ,@("notificaci$($O2)n","notificaci$($o)n")
    ,@("NotificaciÓn",   "Notificaci$($o)n")
    ,@("alimentaci$($O2)n","alimentaci$($o)n")
    ,@("AlimentaciÓn",   "Alimentaci$($o)n")
    ,@("Pol$($I2)tica",  "Pol$($i)tica")
    ,@("pol$($I2)tica",  "pol$($i)tica")
    ,@("D$($I2)as",      "D$($i)as")
    ,@("D$($I2)a",       "D$($i)a")
    ,@("m$($E2)dico",    "m$($e)dico")
    ,@("M$($E2)dico",    "M$($e)dico")
    ,@("T$($E2)rminos",  "T$($e)rminos")
    ,@("T$($E2)rmino",   "T$($e)rmino")
    ,@("pr$($A2)cticas", "pr$($a)cticas")
    ,@("m$($A2)s",       "m$($a)s")
    ,@("M$($A2)s",       "M$($a)s")
    ,@("est$($A2) ",     "est$($a) ")
    ,@("est$($A2)n",     "est$($a)n")
    ,@("M$($E2)dico",    "M$($e)dico")
    ,@("qu$($E2) ",      "qu$($e) ")
    ,@("cualquier",      "cualquier")
    ,@("DespuÉs",        "Despu$($e)s")
    ,@("despuÉs",        "despu$($e)s")
    ,@("tambiÉn",        "tambi$($e)n")
    ,@("TambiÉn",        "Tambi$($e)n")
    ,@("$($O2)n",        "$($o)n")
)

$files = Get-ChildItem -Path "d:\ChamosFitnessCenter\lib" -Recurse -Filter "*.dart"
$totalFixed = 0

foreach ($file in $files) {
    $content = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    $hasFffd = ($content.ToCharArray() | Where-Object { [int]$_ -eq 0xFFFD }).Count
    $hasUc = ($content -match "$($O2)n|$($I2)|$($E2)dico|$($A2)s |pr$($A2)")

    if ($hasFffd -eq 0 -and -not $hasUc) { continue }

    $original = $content

    # Pass 1: FFFD
    if ($hasFffd -gt 0) {
        foreach ($pair in $pairs) {
            $content = $content.Replace($pair[0], $pair[1])
        }
    }

    # Pass 2: uppercase accent corrections
    foreach ($pair in $ucPairs) {
        $content = $content.Replace($pair[0], $pair[1])
    }

    $after = ($content.ToCharArray() | Where-Object { [int]$_ -eq 0xFFFD }).Count
    [IO.File]::WriteAllText($file.FullName, $content, [Text.Encoding]::UTF8)
    if ($content -ne $original) {
        Write-Host "OK: $($file.Name) | FFFD antes=$hasFffd | despues=$after"
        $totalFixed++
    }
}

Write-Host ""
Write-Host "Total archivos modificados: $totalFixed"
