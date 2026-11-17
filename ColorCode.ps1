using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Text

class ColorCode {
    static [PSMemberInfoCollection[PSPropertyInfo]]$Options = [Microsoft.PowerShell.PSConsoleReadLine]::GetOptions().PSObject.Properties
    static $ResetColor = [Char]0x1b + '[0m'
    static $DefaultColor = [ColorCode]::Options['DefaultTokenColor'].Value
    static $Colors = @{
        [PSTokenType]::Attribute          = [ColorCode]::Options['TypeColor'].Value
        [PSTokenType]::Command            = [ColorCode]::Options['CommandColor'].Value
        [PSTokenType]::CommandArgument    = [ColorCode]::Options['ParameterColor'].Value
        [PSTokenType]::CommandParameter   = [ColorCode]::Options['ParameterColor'].Value
        [PSTokenType]::Comment            = [ColorCode]::Options['CommentColor'].Value
        # GroupEnd # Multiple colors depending on the depth
        # GroupStart # Multiple colors depending on the depth
        [PSTokenType]::Keyword            = [ColorCode]::Options['KeywordColor'].Value
        [PSTokenType]::LineContinuation   = [ColorCode]::Options['ContinuationPromptColor'].Value
        [PSTokenType]::LoopLabel          = [ColorCode]::Options['EmphasisColor'].Value
        [PSTokenType]::Member             = [ColorCode]::Options['MemberColor'].Value
        # NewLine # not colored
        [PSTokenType]::Number             = [ColorCode]::Options['NumberColor'].Value
        [PSTokenType]::Operator           = [ColorCode]::Options['OperatorColor'].Value
        [PSTokenType]::Position           = [ColorCode]::Options['DefaultTokenColor'].Value        # Position tokens are bogus tokens generated for identifying a location in the script.
        [PSTokenType]::StatementSeparator = [ColorCode]::Options['ContinuationPromptColor'].Value
        [PSTokenType]::String             = [ColorCode]::Options['StringColor'].Value
        [PSTokenType]::Type               = [ColorCode]::Options['TypeColor'].Value
        [PSTokenType]::Unknown            = [ColorCode]::Options['ErrorColor'].Value
        [PSTokenType]::Variable           = [ColorCode]::Options['VariableColor'].Value
    }

    static $GroupColors =
        [ColorCode]::Colors[[PSTokenType]::Command],
        [ColorCode]::Colors[[PSTokenType]::Comment],
        [ColorCode]::Colors[[PSTokenType]::String]

    hidden [String]$Code # String, ScriptBlock (or almost anything else)
    hidden [StringBuilder]$StringBuilder
    hidden [String]$PenColor = [ColorCode]::DefaultColor
    hidden [Int]$Pointer
    hidden [Int]$ColorLength
    hidden [Int]$GroupDepth

    ColorCode($Code) { $this.Code = $Code.ToString() }

    hidden ColorNext([String]$PenColor, [Int]$Length) {
        if ($Length -eq 0) { return }
        if ($this.ColorLength -and $PenColor -ne $this.PenColor -or $Length -lt 0) {
            $this.StringBuilder.Append($this.PenColor)
            $this.StringBuilder.Append($this.Code.SubString($this.Pointer, $this.ColorLength))
            $this.Pointer += $this.ColorLength
            $this.ColorLength = 0
        }
        $this.PenColor = $PenColor
        if ($Length -gt 0) { $this.ColorLength += $Length } # else force pen color change (without content)
    }

    [String]ToString() {
        if ($this.StringBuilder) { return $this.StringBuilder.ToString() }
        $this.StringBuilder = [StringBuilder]::new()
        # $Pointer Points to the position in the original string that hasn't been copied yet
        # $End is where the previous token ended
        $Errors, $Color, $End = $null
        $Tokens = [System.Management.Automation.PSParser]::Tokenize($this.Code, [ref]$Errors)
        if ($Errors) { Throw $Errors }
        foreach ($Token in $Tokens) {
            $Color =
                if ([ColorCode]::Colors.contains($Token.Type))     { [ColorCode]::Colors[$Token.Type] }
                elseif ($Token.Type -eq [PSTokenType]::GroupStart) { [ColorCode]::GroupColors[$this.GroupDepth++ % 3] }
                elseif ($Token.Type -eq [PSTokenType]::GroupEnd)   { [ColorCode]::GroupColors[--$this.GroupDepth % 3] }
                else                                               { [ColorCode]::DefaultColor }

            $this.ColorNext([ColorCode]::DefaultColor, ($Token.Start - $End))
            $this.ColorNext($Color, $Token.Length)
            $End = $Token.Start + $Token.Length
        }
        $Length = $this.Code.Length - $this.Pointer - $this.ColorLength
        if ($Length) { $this.ColorNext([ColorCode]::DefaultColor, $Length) }
        $this.ColorNext([ColorCode]::ResetColor, -1)
        $this.ColorNext($Null, -1)
        return $this.StringBuilder.ToString()
    }
}
