class FormalRule {
    [string] $Premise
    [string] $Conclusion

    FormalRule ([string] $Premise, [string] $Conclusion) {
        $this.Premise = $Premise
        $this.Conclusion = $Conclusion.ToCharArray()
    }

    static [FormalRule] CreateFrom([string] $Text) {
        if (-not $Text -match "\S*\s*->\s*\S*") {
            throw "Wrong format for formal rule."
        }

        $parts = $text -split "->"

        return [FormalRule]::new($parts[0].Trim(), $parts[1].Trim())
    }

    [System.Collections.ArrayList] Apply([string] $word) {
        $Result = New-Object System.Collections.ArrayList

        foreach ($char in $this.Premise) {
            if ($word -notcontains $char) {
                continue;
            }

            $regex = [regex]::new([regex]::Escape($char))

            $w = $word

            do {
                $wl = $w
                $w = $regex.Replace($word, $this.Conclusion, 1)
                [void]$Result.Add($w)
            } while ($wl -ne $w)
        }

        return $Result
    }


}



function ConvertFrom-StringToFormalRule {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]
        $text
    )

    process {
        if ($_) {
            $text = $_
        }

        [FormalRule]::CreateFrom($text);
    }

}

function New-FormalRule([string] $Premise, [string] $Conclusion)  {
    [FormalRule]::new($Premise, $Conclusion)
}

<#
 .Synopsis
  Creates a new grammar.

 .Description
  Creates a new grammar either by simply stating its rules (uppercase letters as variables and lowercase letters
  as terminal symbols) or by entering the 4 tuple G(V, E, P, S)

  S is by default the start symbol
  e is by default the empty word

 .Parameter Start
  The first month to display.

 .Example
   # Create a grammar simply by stating its rules
   # note: that e is reserved for epsilon - the empty word

   New-Grammar S -> aBSc|e, Ba -> ab, Bb -> bB, Bc -> bc
#>
function New-FormalGrammar {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]
        $rules
    )

    end {
        if ($rules -contains "\n") {
            $Seperator = "\r\n"
        } else {
            $Seperator = ", "
        }

        $ParsedRules = $rules -split $Seperator | ForEach-Object { $_.Trim() } | ConvertFrom-StringToFormalRule

        [FormalGrammar]::CreateFromRules($ParsedRules)
    }
}

class FormalGrammar {
    [System.Collections.ArrayList] $Variables
    [System.Collections.ArrayList] $Terminals
    [System.Collections.ArrayList] $Rules
    [string] $StartSymbol

    FormalGrammar($Variables, $Terminals, $Rules, $StartSymbol = "S") {
        $this.Variables = New-Object System.Collections.ArrayList
        $this.Terminals = New-Object System.Collections.ArrayList
        $this.Rules = New-Object System.Collections.ArrayList
        $this.StartSymbol = $StartSymbol

        $Variables | ForEach-Object { [void]$this.Variables.Add($_.ToString()) }
        $Terminals | ForEach-Object { [void]$this.Terminals.Add($_.ToString()) }
        $Rules | ForEach-Object { [void]$this.Rules.Add($_) }
    }

    static [FormalGrammar] CreateFromRules($Rules) {
        $lower = @{}
        $upper = @{}
        $upper["S"] = 1

        $Rules | ForEach-Object {
            $_.ToString().ToCharArray() | ForEach-Object {
                if ($_ -cmatch "[a-z]") {
                    $lower[$_] = 1
                } else {
                    $upper[$_] = 1
                }
            }
        }

        return [FormalGrammar]::new($upper.Keys, $lower.Keys, $Rules, "S")
    }

    [System.Collections.ArrayList] ApplyRulesToWord([string] $Word) {
        $Result = New-Object System.Collections.ArrayList

        foreach ($Rule in $this.Rules) {
            foreach ($w in $Rule.Apply($Word)) {
                [void]$Result.Add($w)
            }
        }

        return $Result
    }

    [string[]] GenerateLanguage([int] $steps = 5) {
        $Words = @{}
        $Words[$this.StartSymbol] = 0

        $Iteration = @{}
        $Iteration[0] = @("S")

        for ($i = 1; $i -le $steps; $i++) {
            foreach ($word in $Iteration[$i]) {
                $NewWords = $this.ApplyRulesToWord($word)
                $Iteration[$i] = New-Object System.Collections.ArrayList

                foreach ($w in $NewWords) {
                    if ($null -ne $Words[$w]) {
                        continue;
                    }

                    [void]$Iteration[$i].Add($w)
                    $Words[$w] = $i
                }

                if($Iteration[$i].Count -eq 0) {
                    break
                }
            }
        }

        $Output = $Words.Keys | ForEach-Object { $_.ToString() }
        return $Output | Sort-Object -Property { $_.length }
    }
}

Set-Alias New-Grammar New-FormalGrammar

$x = New-FormalGrammar "S->b"
$x.Generate(5)