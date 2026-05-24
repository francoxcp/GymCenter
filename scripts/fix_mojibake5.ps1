$R  = [char]0xFFFD
$a  = [char]0x00E1; $Ac = [char]0x00C1
$e  = [char]0x00E9; $Ec = [char]0x00C9
$i  = [char]0x00ED; $Ic = [char]0x00CD
$o  = [char]0x00F3; $Oc = [char]0x00D3
$u  = [char]0x00FA; $Uc2= [char]0x00DA
$n  = [char]0x00F1; $Nc = [char]0x00D1
$x  = [char]0x00D7; $md = [char]0x00B7
$bu = [char]0x2022; $em = [char]0x2014
$en = [char]0x2013; $ar = [char]0x2192

$pairs = @(
    ,@("'$($R) ",                 "'$($bu) ")
    ,@("`n`n$($R) ",              "`n`n$($bu) ")
    ,@("`n$($R) ",                "`n$($bu) ")
    ,@("pr$($R)ximo",             "pr$($o)ximo")
    ,@("pr$($R)xima",             "pr$($o)xima")
    ,@("pr$($R)ximas",            "pr$($o)ximas")
    ,@("pr$($R)ximamente",        "pr$($o)ximamente")
    ,@("Pr$($R)ximo",             "Pr$($o)ximo")
    ,@("Pr$($R)xima",             "Pr$($o)xima")
    ,@("encontr$($R)",            "encontr$($o)")
    ,@("actualiz$($R)",           "actualiz$($o)")
    ,@("complet$($R)",            "complet$($o)")
    ,@("seg$($R)n",               "seg$($u)n")
    ,@("est$($R)n",               "est$($a)n")
    ,@("instant$($R)neo",         "instant$($a)neo")
    ,@("ser$($R) ",               "ser$($a) ")
    ,@("$($R)ndice",              "$($i)ndice")
    ,@("$($R)ndices",             "$($i)ndices")
    ,@("$($R)nico",               "$($u)nico")
    ,@("$($R)nica",               "$($u)nica")
    ,@("$($R)nicamente",          "$($u)nicamente")
    ,@("D$($R)a",                 "D$($i)a")
    ,@("categor$($R)a",           "categor$($i)a")
    ,@("exist$($R)a",             "exist$($i)a")
    ,@("electr$($R)nico",         "electr$($o)nico")
    ,@("electr$($R)nicos",        "electr$($o)nicos")
    ,@("b$($R)ceps",              "b$($i)ceps")
    ,@("B$($R)ceps",              "B$($i)ceps")
    ,@("hu$($R)rfanos",           "hu$($e)rfanos")
    ,@("qu$($R) ",                "qu$($e) ")
    ,@("contrase$($R)a",          "contrase$($n)a")
    ,@("fotograf$($R)as",         "fotograf$($i)as")
    ,@("fotograf$($R)a",          "fotograf$($i)a")
    ,@("Retenci$($R)n",           "Retenci$($o)n")
    ,@("tr$($R)nsito",            "tr$($a)nsito")
    ,@("auditor$($R)as",          "auditor$($i)as")
    ,@("Auditor$($R)as",          "Auditor$($i)as")
    ,@("tecnolog$($R)as",         "tecnolog$($i)as")
    ,@("tecnolog$($R)a",          "tecnolog$($i)a")
    ,@("expl$($R)cito",           "expl$($i)cito")
    ,@("expl$($R)cita",           "expl$($i)cita")
    ,@("precisi$($R)n",           "precisi$($o)n")
    ,@("Precisi$($R)n",           "Precisi$($o)n")
    ,@("espec$($R)ficos",         "espec$($i)ficos")
    ,@("espec$($R)ficas",         "espec$($i)ficas")
    ,@("espec$($R)fico",          "espec$($i)fico")
    ,@("espec$($R)fica",          "espec$($i)fica")
    ,@("Rectificaci$($R)n",       "Rectificaci$($o)n")
    ,@("Revocaci$($R)n",          "Revocaci$($o)n")
    ,@("t$($R)cnicas",            "t$($e)cnicas")
    ,@("T$($R)cnicas",            "T$($e)cnicas")
    ,@("org$($R)nicas",           "org$($a)nicas")
    ,@("Org$($R)nica",            "Org$($a)nica")
    ,@("Interrupci$($R)n",        "Interrupci$($o)n")
    ,@("Limitaci$($R)n",          "Limitaci$($o)n")
    ,@("variaci$($R)n",           "variaci$($o)n")
)

$ucPairs = @(
    ,@("sesi$($Oc)n",          "sesi$($o)n")
    ,@("Sesi$($Oc)n",          "Sesi$($o)n")
    ,@("funci$($Oc)n",         "funci$($o)n")
    ,@("Funci$($Oc)n",         "Funci$($o)n")
    ,@("informaci$($Oc)n",     "informaci$($o)n")
    ,@("Informaci$($Oc)n",     "Informaci$($o)n")
    ,@("actualizaci$($Oc)n",   "actualizaci$($o)n")
    ,@("Actualizaci$($Oc)n",   "Actualizaci$($o)n")
    ,@("aplicaci$($Oc)n",      "aplicaci$($o)n")
    ,@("Aplicaci$($Oc)n",      "Aplicaci$($o)n")
    ,@("configuraci$($Oc)n",   "configuraci$($o)n")
    ,@("notificaci$($Oc)n",    "notificaci$($o)n")
    ,@("Notificaci$($Oc)n",    "Notificaci$($o)n")
    ,@("alimentaci$($Oc)n",    "alimentaci$($o)n")
    ,@("Alimentaci$($Oc)n",    "Alimentaci$($o)n")
    ,@("comunicaci$($Oc)n",    "comunicaci$($o)n")
    ,@("descripci$($Oc)n",     "descripci$($o)n")
    ,@("Descripci$($Oc)n",     "Descripci$($o)n")
    ,@("condici$($Oc)n",       "condici$($o)n")
    ,@("Condici$($Oc)n",       "Condici$($o)n")
    ,@("Pol$($Ic)tica",        "Pol$($i)tica")
    ,@("pol$($Ic)tica",        "pol$($i)tica")
    ,@("D$($Ic)as",            "D$($i)as")
    ,@("D$($Ic)a",             "D$($i)a")
    ,@("m$($Ec)dico",          "m$($e)dico")
    ,@("M$($Ec)dico",          "M$($e)dico")
    ,@("T$($Ec)rminos",        "T$($e)rminos")
    ,@("T$($Ec)rmino",         "T$($e)rmino")
    ,@("pr$($Ac)cticas",       "pr$($a)cticas")
    ,@("m$($Ac)s",             "m$($a)s")
    ,@("M$($Ac)s",             "M$($a)s")
    ,@("est$($Ac) ",           "est$($a) ")
    ,@("est$($Ac)n",           "est$($a)n")
    ,@("Despu$($Ec)s",         "despu$($e)s")
    ,@("despu$($Ec)s",         "despu$($e)s")
    ,@("tambi$($Ec)n",         "tambi$($e)n")
    ,@("Tambi$($Ec)n",         "Tambi$($e)n")
    ,@("qu$($Ec) ",            "qu$($e) ")
)

$files = Get-ChildItem -Path "d:\ChamosFitnessCenter\lib" -Recurse -Filter "*.dart"
$totalFixed = 0

foreach ($file in $files) {
    $content = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    $before = ($content.ToCharArray() | Where-Object { [int]$_ -eq 0xFFFD }).Count
    $hasUcAccent = $content.IndexOf($Oc) -ge 0 -or $content.IndexOf($Ic) -ge 0 -or $content.IndexOf($Ec) -ge 0 -or $content.IndexOf($Ac) -ge 0

    if ($before -eq 0 -and -not $hasUcAccent) { continue }

    $original = $content

    if ($before -gt 0) {
        foreach ($pair in $pairs) {
            $content = $content.Replace($pair[0], $pair[1])
        }
    }

    if ($hasUcAccent) {
        foreach ($pair in $ucPairs) {
            $content = $content.Replace($pair[0], $pair[1])
        }
    }

    $after = ($content.ToCharArray() | Where-Object { [int]$_ -eq 0xFFFD }).Count

    if ($content -ne $original) {
        [IO.File]::WriteAllText($file.FullName, $content, [Text.Encoding]::UTF8)
        Write-Host "OK: $($file.Name) | FFFD antes=$before | despues=$after"
        $totalFixed++
    }
}

Write-Host ""
Write-Host "Total archivos modificados: $totalFixed"
