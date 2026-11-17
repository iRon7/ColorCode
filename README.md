# ColorCode

This class colors the code provided in a expression string or script block.

## Syntax

```PowerShell
[ColorCode]'<Expression>'
```

```PowerShell
[ColorCode]{<expression>}
```

## Examples

### Example 1

Color an assignment expression

```PowerShell
$Code = '$Object = [PSCustomObject]@{ id = "Foo"; code = { Write-Host "Bar" } }'
[ColorCode]$Code
```

![Colored command line](Example1.png)

## Examples

### Example 2

Embedded colored code in a string:

```PowerShell
"This code: $([ColorCode]{$HashTable = @{ Foo = 'Bar' }}) is colored"
```

![Embedded color code](Example2.png)