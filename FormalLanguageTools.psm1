class FormalRule {
    [string] $Premise
    [string] $Conclusion

    FormalRule ([string] $Premise, [string] $Conclusion) {
        $this.Premise = $Premise
        $this.Conclusion = $Conclusion
    }

    static [FormalRule] CreateFrom([string] $Text) {
        if (-not ($Text -match "\S*\s*->\s*\S*")) {
            throw "Wrong format for formal rule."
        }

        $parts = $text -split "->"

        return [FormalRule]::new($parts[0].Trim(), $parts[1].Trim())
    }



    [System.Collections.ArrayList] Apply([string] $word) {
        $Result = New-Object System.Collections.ArrayList
        # $replacableSymbols = $this.Premise.ToCharArray() | Where-Object { $_ -cmatch "[A-Z]" }
        $tmpbefore = $word

        if (!$word.Contains($this.Premise)) {
            # Write-Host -fore yellow "Premise not found $word $($this.Premise)"
            return $result
        }


        $regex = [regex]::new([regex]::Escape($this.Premise))
        [void]$Result.Add($regex.Replace($word, $this.Conclusion, 1))


        # Todo: Replace recursion with loop
        $index = $word.IndexOf($this.Premise)
        $this.Apply($word.Substring($index + 1)) | ForEach-Object {
            [void] $Result.Add($_)
        }

        if ($tmpbefore -ne $word) {
            Write-Host -Fore Cyan "$tmpbefore $($this.Premise) -> $($this.conclusion) $word"
        }

        # todo this will fail e. g. if we have Sa -> xy and aS -> z. aS will never be applied
        # "aSaSa" with rule aSa-> bb has to output bbSa and aSbb

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
        if ($rules.Contains("\n")) {
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

        #Add terminal rule
        [void]$this.Rules.Add([FormalRule]::new($StartSymbol, ""))
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

                # Write-Host -Fore Red "Iteration: $i, Word: $word, New words: $($NewWords.count)"
                # $NewWords | % { Write-Host -Fore Green "$i : $_" }

                foreach ($w in $NewWords) {
                    # Write-Host -fore cyan "Add new word $i $w"
                    if ($Words.ContainsKey($w)) {
                        continue;
                    }

                    [void]$Iteration[$i].Add($w)
                    $Words[$w] = $i
                }
            }
            # Write-Host -fore cyan "End foreach $i : $($Iteration[$i-1].Count)"
        }

        $Output = $Words.Keys | ForEach-Object { $_.ToString() }
        return $Output | Sort-Object -Property { $_.length }, { $_ }
    }

    [System.Collections.ArrayList] ApplyRulesWithBruteForce($Word, $MaxLength) {
        $result = New-Object System.Collections.ArrayList
        $NonTerminalWords = New-Object System.Collections.Queue

        # POWERSHELL HASHTABLE INDICES ARE CASEINSENSITIVE! Use: System.Collections.Hashtable
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

                if ($count % 1000 -eq 0) {
                    Write-Host -Fore yellow "Generated $count words. So far $($result.count) (non-unique) terminal words"
                }

                if ($NewWord.Length -gt $MaxLength) {
                    continue
                }




                if (Test-IsTerminalWord $NewWord) {
                    # return results
                    [void]$result.Add($NewWord)
                } else {
                    # better than nothing


                    [void] $NonTerminalWords.Enqueue($NewWord)
                }
            }
        }

        return $result
    }
}



function Test-IsTerminalWord {
    param (
        [string] $word
    )

    return -not ($word -cmatch "[A-Z]")
}


# Temp for debug purposes
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

                # Warning/Bug: has to be rule depentend.
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

Set-Alias New-Grammar New-FormalGrammar


# $gr = (New-FormalGrammar "S->aBSc, Ba->aB, Bb -> bB, Bc -> bc")
# $gr.ApplyRulesWithBruteForce("S", 10)
# abc
# aabbcc
# aabbccc <---- where does this come from?
# aaabbbccc