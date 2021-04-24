
function Get-ThueMorse([int] $n) {
    if (-not $global:ThueMorseCache) {
        $global:ThueMorseCache = @{};
        $global:ThueMorseCache[0] = "0";
    }

    if ($global:ThueMorseCache.ContainsKey($n)) {
        return $global:ThueMorseCache[$n]
    }

    $m = Get-ThueMorse($n - 1)
    $mInverse = ($m.ToCharArray() | % {
        if($_ -eq '0') {'1'}else{'0'}
    }) -join ''


    $result = ($m + $mInverse)
    $global:ThueMorseCache[$n] = $result
    return $result
}

function Get-ThueMorseWithDec([int] $n) {
    Get-ThueMorse $n | Out-Null

    0..$n | % {
        [PSCustomObject]@{
            ThueMorse = $global:ThueMorseCache[$_]
            Decimal = [Convert]::ToInt64($global:ThueMorseCache[$_], 2)
        }
    }
}


function Chunk([string] $str, [int] $chunkSize)
{
    for ($i = 0; $i -lt $str.Length; $i += $chunkSize) {
        $str.Substring($i, $chunkSize);
    }
}

# > Get-ThueMorse 5
# 01101001100101101001011001101001

# > 1..8 | % { [pscustomobject]@{i = $_; Value = (Get-ThueMorse $_)} }
#
# i Value
# - -----
# 0 0
# 1 01
# 2 0110
# 3 01101001
# 4 0110100110010110
# 5 01101001100101101001011001101001
# 6 0110100110010110100101100110100110010110011010010110100110010110
# 7 011010011001011010010110011010011001011001101001011010011001011010010110011010010110...
# 8 011010011001011010010110011010011001011001101001011010011001011010010110011010010110...

# > $x = Get-ThueMorse 7
# > Chunk $x 16
# 0110100110010110
# 1001011001101001
# 1001011001101001
# 0110100110010110
# 1001011001101001
# 0110100110010110
# 0110100110010110
# 1001011001101001