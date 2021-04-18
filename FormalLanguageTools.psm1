# This is more experimental than working and probably contains bugs

# Classes ------------------------------------------------------------------
class FormalRule {
    [string] $Premise
    [string] $Conclusion

    FormalRule ([string] $Premise, [string] $Conclusion) {
        $this.Premise = $Premise
        $this.Conclusion = $Conclusion
    }

    [System.Collections.ArrayList] Apply([string] $word) {
        $Result = New-Object System.Collections.ArrayList
        $tmpbefore = $word

        if (!$word.Contains($this.Premise)) {
            return $result
        }


        $regex = [regex]::new([regex]::Escape($this.Premise))
        [void]$Result.Add($regex.Replace($word, $this.Conclusion, 1))


        # Todo: Replace recursion with loop
        $index = $word.IndexOf($this.Premise)
        $wordLeft = $word.Substring(0, $index+1)
        $this.Apply($word.Substring($index + 1)) | ForEach-Object {
            [void] $Result.Add($wordLeft + $_)
        }

        if ($tmpbefore -ne $word) {
            Write-Host -Fore Cyan "$tmpbefore $($this.Premise) -> $($this.conclusion) $word"
        }


        return $Result
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

        if ($Variables) {
            $Variables | ForEach-Object { [void]$this.Variables.Add($_.ToString()) }
        }

        if ($Terminals) {
            $Terminals | ForEach-Object { [void]$this.Terminals.Add($_.ToString()) }
        }

        if ($Rules) {
            $Rules | ForEach-Object { [void]$this.Rules.Add($_) }
        }

        #Add terminal rule
        [void]$this.Rules.Add([FormalRule]::new($StartSymbol, ""))
    }

    [void] AddRuleAutoVariables($Rule) {
        # Adds a rule and automatically assumes capital letters to be variables and lower letters to be terminals
        $Rule.Premise, $Rule.Conclusion | ForEach-Object {
            $_.ToCharArray() | ForEach-Object {
                if ($_ -cmatch "[a-z]") {
                    if ($this.Terminals -notcontains $_) {
                        [void]$this.Terminals.Add($_)
                    }
                } else {
                    if ($this.Variables -notcontains $_) {
                        [void]$this.Variables.Add($_)
                    }
                }
            }
        }

        [void]$this.Rules.Add($Rule)
    }

    static [FormalGrammar] CreateFromRules($Rules) {
        $lower = New-Object System.Collections.Hashtable
        $upper = New-Object System.Collections.Hashtable
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
        $Words = New-Object System.Collections.Hashtable
        $Iteration = New-Object System.Collections.Hashtable

        $Words[$this.StartSymbol] = 0
        $Iteration[0] = @($this.StartSymbol)

        for ($i = 1; $i -le $steps; $i++) {
            $Iteration[$i] = New-Object System.Collections.ArrayList
            foreach ($word in $Iteration[$i-1]) {
                $NewWords = $this.ApplyRulesToWord($word)

                foreach ($w in $NewWords) {
                    if ($Words.ContainsKey($w)) {
                        continue;
                    }

                    [void]$Iteration[$i].Add($w)
                    $Words[$w] = $i
                }
            }
        }

        $Output = $Words.Keys | ForEach-Object { $_.ToString() }
        return $Output | Sort-Object -Property { $_.length }, { $_ }
    }

    [System.Collections.ArrayList] ApplyRulesWithBruteForce($Word, $MaxLength, $MaxTries) {
        $result = New-Object System.Collections.ArrayList
        $NonTerminalWords = New-Object System.Collections.Queue

        $Generated = New-Object System.Collections.Hashtable

        $count = 0;

        if (-not $MaxLength) {
            $MaxLength = $Word.Length + 5
        }

        [void]$NonTerminalWords.Enqueue($word)

        while ($NonTerminalWords.Count -gt 0) {
            $currentWord = $NonTerminalWords.Dequeue()

            if ($Generated.ContainsKey($currentWord)) {
                continue;
            } else {
                $Generated[$currentWord] = $true
            }


            foreach ($NewWord in $this.ApplyRulesToWord($currentWord)) {
                $count++

                if ($count -eq $MaxTries) {
                    Write-Host -ForegroundColor Yellow "Generated $count words. Ending search."
                }

                if ($count % 1000 -eq 0) {
                    Write-Verbose "Generated $count words. So far $($result.count) terminal words (including duplicates)"
                }



                if ($NewWord.Length -gt $MaxLength) {
                    continue
                }

                if (Test-IsTerminalWord $NewWord) {
                    # return results
                    [void]$result.Add($NewWord)
                } else {
                    [void] $NonTerminalWords.Enqueue($NewWord)
                }
            }
        }

        return $result
    }
}

# Functions ------------------------------------------------------------------

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

   New-Grammar "S -> aBSc|e, Ba -> ab, Bb -> bB, Bc -> bc"

  .EXAMPLE
  # Convert string to rules, than create a new grammar from that rules and finally generate some words and apply the
  # rules till any terminal words using the rules are found. (Find-TerminalWord does not apply rules that will cuase the
  # new word to be longer than the old one, if not specified otherwise)

  "S->aBSc, Ba->aB, Bb -> bB, Bc -> bc" | ConvertTo-FormalLanguageRules | New-FormalGrammar |
    Get-FormalLanguageWords -Iterations 5 | Find-TerminalWord


  .EXAMPLE
  # See the example above. Here the additional iterations when generating will mean we have more initial words.
  # In the process to find terminal words an additional length of 10 of the generated words is allowed.
  # Decrease these numbers if it takes too long.

  # "S -> abc, S -> aXbc, Xb -> bX, Xc -> Ybcc, bY -> Yb, aY -> aa, aY -> aaX" |
  #   ConvertTo-FormalLanguageRules | New-FormalGrammar | Get-FormalLanguageWords -Iterations 15 |
  #   Find-TerminalWord -MaxAdditionLength 10

#>
function New-FormalGrammar {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Rules
    )

    begin {
        $CollectedRules = New-Object System.Collections.ArrayList

        $Grammar = [FormalGrammar]::new($null, $null, $null, "S")
        Set-LastGrammar $Grammar
    }

    process {
        if ($_) {
            [void] $CollectedRules.Add($_)
        }

        $Rule = $null;
        if ($_ -is [string]) {
            $Rule = $_ | ConvertTo-FormalGrammarRules
        } else {
            $Rule = $_
        }

        $Rule | ForEach-Object {
            $Grammar.AddRuleAutoVariables($_)
        }
    }

    end {
        $Grammar
    }
}


function Test-IsTerminalWord {
    param (
        [string] $word
    )

    return -not ($word -cmatch "[A-Z]")
}


# Temp for debug purposes
# Do not use this
<#
TODO
function Get-TerminalWords($FormalLanguage, $Words) {
    # Bug: Some terminal rules need a nonterminal rule applied first, before they become applicable
    # Doing this right would require a searchtree which probably would need some optimizations
    # Alternatively just bruteforce it and
    $TerminalRules = $FormalLanguage.Rules | Where-Object { -not ($_.Conclusion -cmatch "[A-Z]") -or $_.Conclusion -eq "" }
    $TerminalWords = New-Object System.Collections.ArrayList
    $Generated = New-Object System.Collections.Hashtable

    $NonTerminalWords = New-Object System.Collections.Queue

    foreach ($w in $Words) {
        [void] $NonTerminalWords.Enqueue($w)
    }

    while ($NonTerminalWords.Count -gt 0) {
        $w = $NonTerminalWords.Dequeue()

        foreach ($rule in $TerminalRules) {
            foreach ($NewWord in $rule.Apply($w)) {
                Write-Host -Fore red $NewWord

                # Warning/Bug: has to be rule dependend or we prune possible words
                if ($Generated.ContainsKey($NewWord)) {
                    continue
                } else {
                    $Generated[$NewWord] = $true
                }


                if (Test-IsTerminalWord $NewWord) {
                    [void]$TerminalWords.Add($NewWord)
                } else {
                    [void]$NonTerminalWords.Enqueue($NewWord)
                }

            }
        }
    }

    return $TerminalWords
}
#>



function Get-UniqueInstant {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        $elem
    )

    begin {
        $cache = New-Object System.Collections.Hashtable
    }

    process {
        if ($_) {
            $elem = $_
        }

        if (!$cache.ContainsKey($elem)) {
            $cache[$elem] = $true
            $elem
        }
    }
}




function ConvertTo-FormalGrammarRules {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        $Rules
    )

    process {
        if (-not ($_ -is [string])) {
            $Props = $_ | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name

            if ($_ -contains "Conclusion" -and $_ -contains "Premise") {
                $_
                return
            }
        }

        if (-not $_) {
            $Rules | ConvertTo-FormalGrammarRules
            return
        }

        $Rule = $_.ToString()

        $Separators = @(",", ";", "`r`n", "`n")

        foreach ($Sep in $Separators) {
            if ($Rule.Contains($Sep)) {
                # if rules are given as a single string, split it and pass it again to the function
                $Rule -split $Sep | ForEach-Object {
                    $_.Trim()
                } | Where-Object {
                    $_
                } | ConvertTo-FormalGrammarRules

                return
            }
        }

        if (-not $Rule.Contains("->")) {
            Write-Error "Cannot parse rule: $Rule"
            return
        }

        $tmp = $Rule -split "->" | ForEach-Object { $_.Trim() }

        New-FormalGrammarRule -Premise $tmp[0] -Conclusion $tmp[1]
    }
}

function New-FormalGrammarRule {
    [CmdletBinding()]
    param (
        [string]
        $Premise,

        [string]
        $Conclusion
    )

    [FormalRule]::new($Premise.Trim(), $Conclusion.Trim())
}

function Get-FormalLanguageWords {
    [CmdletBinding()]
    param (
        # The grammar to create words from
        [Parameter(ValueFromPipeline=$true)]
        [FormalGrammar]
        $Grammar,

        $Iterations = 5,

        [switch]
        $IncludeSteps
    )

    begin {
        if ($IncludeSteps) {
            Write-Host -ForegroundColor Yellow "Sorry this is not implemented yet"
        }

        if(!$Grammar) {
            $Grammar = Get-LastGrammar
        }
    }

    process {
        $Grammar.GenerateLanguage($Iterations)
    }
}

function Find-TerminalWord {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]
        $NonTerminalWord,

        [FormalGrammar]
        $Grammar,

        $MaxAdditionLength = 3,

        $MaxTries = 10000,

        [switch]
        $IncludeSteps = $false,

        [switch]
        $IncludeDuplicates = $false
    )

    begin {
        if ($IncludeSteps) {
            Write-Host -ForegroundColor Yellow "Sorry this is not implemented yet"
        }

        if(!$Grammar) {
            $Grammar = Get-LastGrammar
        }


        $cache = New-Object System.Collections.Hashtable

    }

    process {
        foreach ($elem in $Grammar.ApplyRulesWithBruteForce($NonTerminalWord, $NonTerminalWord.Length + $MaxAdditionLength, $MaxTries)) {
            if (!$IncludeDuplicates -and !$cache.ContainsKey($elem)) {
                $cache[$elem] = $true
                $elem
            }

            if ($IncludeDuplicates) {
                $elem
            }
        }


    }

    end {

    }
}

Write-Verbose "If not specified, the last used/created grammar will be used for all cmdlets!" -Verbose

function Set-LastGrammar([FormalGrammar] $Grammar) {
    $Global:FormalLanguageToolsLastLanguage = $Grammar
}


function Get-LastGrammar([FormalGrammar] $Grammar) {
    if ($Global:FormalLanguageToolsLastLanguage) {
        $Global:FormalLanguageToolsLastLanguage
    } else {
        throw "No grammar found. Use New-FormalGrammar to create a new one."
    }
}



# Notes ------------------------------------------------------------------
# TODO: Make output into custom objects and add history which rules where used in which order

# These things currently work:

# Import-Module FormalLanguageTools.psm1 -Force
# "S->aBSc, Ba->aB, Bb -> bB, Bc -> bc" | ConvertTo-FormalLanguageRules | New-FormalGrammar |
#   Get-FormalLanguageWords -Iterations 5 | Find-TerminalWord

# Output:
#
# abc
# aabbcc
# aaabbbccc
# aaaabbbbcccc
# aaaaabbbbbccccc
# aaaaaabbbbbbcccccc

# "S -> abc, S -> aXbc, Xb -> bX, Xc -> Ybcc, bY -> Yb, aY -> aa, aY -> aaX" |
#   ConvertTo-FormalLanguageRules | New-FormalGrammar | Get-FormalLanguageWords -Iterations 15 |
#   Find-TerminalWord -MaxAdditionLength 10

# Output:
#
# abc
# aabbcc
# aaabbbccc
# aaaabbbbcccc
# aaaaabbbbbccccc
# aaaaaabbbbbbcccccc
# aaaaaaabbbbbbbccccccc

# Aliases ------------------------------------------------------------------
Set-Alias New-Grammar                   New-FormalGrammar
Set-Alias Get-WordsFromGrammar          Get-FormalLanguageWords
Set-Alias Get-Words                     Get-FormalLanguageWords
Set-Alias ConvertTo-FormalLanguageRules ConvertTo-FormalGrammarRules