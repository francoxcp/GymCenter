$R  = [char]0xFFFD
$a  = [char]0x00E1; $Ac = [char]0x00C1
$e  = [char]0x00E9; $Ec = [char]0x00C9
$i  = [char]0x00ED; $Ic = [char]0x00CD
$o  = [char]0x00F3; $Oc = [char]0x00D3
$u  = [char]0x00FA
$n  = [char]0x00F1
$x  = [char]0x00D7; $md = [char]0x00B7
$em = [char]0x2014

$pairs = @(
    # Separadores UI - mas especificos primero
    ,@("series $($R) $",             "series $($x) $")
    ,@("reps $($R) $",               "reps $($x) $")
    ,@("} $($R) `${",                "} $($x) `${")
    ,@("' $($R) $",                  "' $($md) $")
    ,@(" $($R) ",                    " $($em) ")
    # Palabras que empiezan con mayuscula - terminaciones -cion / -sion
    ,@("Introducci$($R)n",           "Introducci$($o)n")
    ,@("Aceptaci$($R)n",             "Aceptaci$($o)n")
    ,@("Encriptaci$($R)n",           "Encriptaci$($o)n")
    ,@("Autenticaci$($R)n",          "Autenticaci$($o)n")
    ,@("Protecci$($R)n",             "Protecci$($o)n")
    ,@("Validaci$($R)n",             "Validaci$($o)n")
    ,@("Gesti$($R)n",                "Gesti$($o)n")
    ,@("Duraci$($R)n",               "Duraci$($o)n")
    ,@("Nutrici$($R)n",              "Nutrici$($o)n")
    ,@("Celebraci$($R)n",            "Celebraci$($o)n")
    ,@("celebraci$($R)n",            "celebraci$($o)n")
    ,@("Anticipaci$($R)n",           "Anticipaci$($o)n")
    ,@("anticipaci$($R)n",           "anticipaci$($o)n")
    ,@("Aportaci$($R)n",             "Aportaci$($o)n")
    # Con capital C
    ,@("Calor$($R)as",               "Calor$($i)as")
    ,@("Calor$($R)a",                "Calor$($i)a")
    ,@("Categor$($R)a",              "Categor$($i)a")
    # Con capital F
    ,@("Fotograf$($R)as",            "Fotograf$($i)as")
    ,@("Fotograf$($R)a",             "Fotograf$($i)a")
    # Con capital P
    ,@("Prote$($R)nas",              "Prote$($i)nas")
    ,@("Prote$($R)na",               "Prote$($i)na")
    ,@("Pl$($R)tano",                "Pl$($a)tano")
    ,@("P$($R)rdida",                "P$($e)rdida")
    # Mas palabras con o
    ,@("duraci$($R)n",               "duraci$($o)n")
    ,@("gesti$($R)n",                "gesti$($o)n")
    ,@("lim$($R)n",                  "lim$($o)n")
    ,@("Salm$($R)n",                 "Salm$($o)n")
    ,@("salm$($R)n",                 "salm$($o)n")
    # Mas palabras con a
    ,@("tama$($R)o",                 "tama$($n)o")
    ,@("Tama$($R)o",                 "Tama$($n)o")
    ,@("m$($R)x",                    "m$($a)x")
    ,@("M$($R)x",                    "M$($a)x")
    ,@("Ma$($R)ana",                 "Ma$($n)ana")
    ,@("dise$($R)o",                 "dise$($n)o")
    ,@("due$($R)o",                  "due$($n)o")
    ,@("a$($R)adidos",               "a$($n)adidos")
    ,@("Rep$($R)blica",              "Rep$($u)blica")
    ,@("az$($R)cares",               "az$($u)cares")
    ,@("trav$($R)s",                 "trav$($e)s")
    ,@("regir$($R)n",                "regir$($a)n")
    ,@("interpretar$($R)n",          "interpretar$($a)n")
    ,@("vac$($R)os",                 "vac$($i)os")
    ,@("vac$($R)as",                 "vac$($i)as")
    # Palabras con i
    ,@("f$($R)sico",                 "f$($i)sico")
    ,@("F$($R)sico",                 "F$($i)sico")
    ,@("Caf$($R)",                   "Caf$($e)")
    ,@("num$($R)rico",               "num$($e)rico")
    ,@("Num$($R)rico",               "Num$($e)rico")
    ,@("Estad$($R)stica",            "Estad$($i)stica")
    ,@("estad$($R)stica",            "estad$($i)stica")
    ,@("M$($R)todo",                 "M$($e)todo")
    ,@("m$($R)todo",                 "m$($e)todo")
    # Palabras con u
    ,@("prote$($R)na",               "prote$($i)na")
    ,@("prote$($R)nas",              "prote$($i)nas")
    ,@("Contrase$($R)a",             "Contrase$($n)a")
    ,@("secci$($R)n",               "secci$($o)n")
    ,@("Secci$($R)n",               "Secci$($o)n")
    # Reparar Orgúnica -> Orgánica (wrong accent used)
    ,@("Org$($u)nica",               "Org$($a)nica")
    # Uppercase accent corrections
    ,@("Bot$($Oc)n",                 "Bot$($o)n")
    ,@("bot$($Oc)n",                 "bot$($o)n")
    ,@("t$($Ec)rminos",              "t$($e)rminos")
    ,@("Men$($R) ",                  "Men$($u) ")
    # Catch remaining
    ,@("$($R)",                      "?")
)

$files = Get-ChildItem -Path "d:\ChamosFitnessCenter\lib" -Recurse -Filter "*.dart"
$totalFixed = 0

foreach ($file in $files) {
    $content = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    $before = ($content.ToCharArray() | Where-Object { [int]$_ -eq 0xFFFD }).Count
    if ($before -eq 0) { continue }

    $original = $content
    foreach ($pair in $pairs) {
        $content = $content.Replace($pair[0], $pair[1])
    }

    $after = ($content.ToCharArray() | Where-Object { [int]$_ -eq 0xFFFD }).Count

    if ($content -ne $original) {
        [IO.File]::WriteAllText($file.FullName, $content, [Text.Encoding]::UTF8)
        Write-Host "OK: $($file.Name) | antes=$before | despues=$after"
        $totalFixed++
    }
}

Write-Host ""
Write-Host "Total archivos modificados: $totalFixed"
