#Requires -Modules @{ModuleName="Pester"; ModuleVersion="6.0"}

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'False positive')]
param([alias("Path")]$PrototypePath)

BeforeAll {
    Set-StrictMode -Version Latest

    $Esc = [Char]0x1b
    $CC = [Regex]"$Esc\[\d+m"
    . .\ColorCode.ps1
}

Describe 'ColorCode' -ForEach @(
        @{
            Name = 'One line'
            Code = { $Foo = "Bar" }
            Ansi = '`e[37m `e[92m$Foo`e[37m `e[90m=`e[37m `e[36m"Bar"`e[37m `e[0m'
        },
        @{
            Name = 'Condensed'
            Code = {$Foo="Bar"}
            Ansi = '`e[92m$Foo`e[90m=`e[36m"Bar"`e[0m'
        },
        @{
            Name = 'Multi line'
            Code =
{
    $Foo = "Bar"
}
            Ansi =
'`e[37m
    `e[92m$Foo`e[37m `e[90m=`e[37m `e[36m"Bar"`e[37m
`e[0m'
        },
        @{
            Name = 'Grouping'
            Code = { $a = @( @( @( @( "Test" ) ) ) ) }
            Ansi = '`e[37m `e[92m$a`e[37m `e[90m=`e[37m `e[93m@(`e[37m `e[32m@(`e[37m `e[36m@(`e[37m `e[93m@(`e[37m `e[36m"Test"`e[37m `e[93m)`e[37m `e[36m)`e[37m `e[32m)`e[37m `e[93m)`e[37m `e[0m'
        },
        @{
            Name = 'Grouping condensed'
            Code = {$a=@(@(@(@("Test"))))}
            Ansi = '`e[92m$a`e[90m=`e[93m@(`e[32m@(`e[36m@(`e[93m@(`e[36m"Test"`e[93m)`e[36m)`e[32m)`e[93m)`e[0m'
        },
        @{
            Name = 'Hashtable'
            Code = { $h = @{ number = 42; text = "Hello World" } }
            Ansi = '`e[37m `e[92m$h`e[37m `e[90m=`e[37m `e[93m@{`e[37m number `e[90m=`e[37m `e[97m42`e[37m; text `e[90m=`e[37m `e[36m"Hello World"`e[37m `e[93m}`e[37m `e[0m'
        },
        @{
            Name = 'Comment'
            Code = '$a = 1 # Test'
            Ansi = '`e[92m$a`e[37m `e[90m=`e[37m `e[97m1`e[37m `e[32m# Test`e[0m'
        }
    ) {
    Context '<Name>' {

        BeforeAll {
            $Colored = [ColorCode]$Code
        }

        It "Bare content" {
            $Colored -replace $CC | Should-BeString $Code
        }

        It "Starts with color code" {
            $Colored | Should -Match "^$CC"
        }

        It "Consecutive color codes" {
            $Colored | Should -Not -Match "$CC$CC"
        }

        It "Repeating color codes" {
            $n = $null
            $CC.Matches($Colored).Value.where({ $n -eq $_; $n = $_ }, 'First') | Should-BeNull
        }

        It "Ends with reset color" {
            $Colored | Should -Match "$Esc\[0m$"
        }

        It "Color string" {
            $Colored | Should-Be $Ansi.replace('`e', "`e")
        }
    }
}