function Add-WordPicture {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Words.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Words.NET.InsertBeforeOrAfter] $Paragraph,
        [Xceed.Words.NET.DocXElement] $Picture,
        [alias('FileImagePath')][string] $ImagePath,
        [Alignment] $Alignment,
        [int] $Rotation,
        [switch] $FlipHorizontal,
        [switch] $FlipVertical,
        [int] $ImageWidth,
        [int] $ImageHeight,
        [string] $Description,
        [bool] $Supress = $false
    )
    if ([string]::IsNullOrEmpty($Paragraph)) {
        $Paragraph = Add-WordParagraph -WordDocument $WordDocument -Supress $false
    }
    if ($null -eq $Picture) {
        if ($ImagePath -ne '' -and (Test-Path($ImagePath))) {
            $Image = $WordDocument.AddImage($ImagePath)
            $Picture = $Image.CreatePicture()
        } else {
            Write-Warning "Add-WordPicture - Path to ImagePath ($ImagePath) was incorrect. Aborting."
            return
        }
    }
    if ($Rotation -ne 0) { $Picture.Rotation = $Rotation }
    if ($FlipHorizontal -ne $false) { $Picture.FlipHorizontal = $FlipHorizontal }
    if ($FlipVertical -ne $false) { $Picture.FlipVertical = $FlipVertical }
    if (-not [string]::IsNullOrEmpty($Description)) { $Picture.Description = $Description }
    if ($ImageWidth -ne 0) { $Picture.Width = $ImageWidth }
    if ($ImageHeight -ne 0) { $Picture.Height = $ImageHeight }
    $Data = $Paragraph.AppendPicture($Picture)
    if ($Alignment) {
        $Data = Set-WordTextAlignment -Paragraph $Data -Alignment $Alignment
    }
    if ($Supress) { return $Data } else { return }
}

function Get-WordPicture {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Words.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Words.NET.InsertBeforeOrAfter] $Paragraph,
        [switch] $ListParagraphs,
        [switch] $ListPictures,
        [nullable[int]] $PictureID
    )
    if ($ListParagraphs -eq $true -and $ListPictures -eq $true) {
        throw 'Only one option is possible at time (-ListParagraphs or -ListPictures)'
    }
    if ($ListParagraphs) {
        $List = New-ArrayList
        $Paragraphs = $WordDocument.Paragraphs
        foreach ($p in $Paragraphs) {
            if ($p.Pictures -ne $null) {
                Add-ToArray -List $List -Element $p
            }
        }
        return $List
    }
    if ($ListPictures) {
        return $WordDocument.Pictures
    }
    if ($PictureID -ne $null) {
        return $WordDocument.Pictures[$PictureID]
    }
}

function Remove-WordPicture {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Words.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Words.NET.InsertBeforeOrAfter] $Paragraph,
        [int] $PictureID,
        [bool] $Supress
    )
    if ($Paragraph.Pictures[$PictureID] -ne $null) {
        $Paragraph.Pictures[$PictureID].Remove()
    }
    if ($supress) { return } else { return $Paragraph}
}

function Set-WordPicture {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Words.NET.Container]$WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Words.NET.InsertBeforeOrAfter] $Paragraph,
        [Xceed.Words.NET.DocXElement] $Picture,
        [string] $ImagePath,
        [int] $Rotation,
        [switch] $FlipHorizontal,
        [switch] $FlipVertical,
        [int] $ImageWidth,
        [int] $ImageHeight,
        [string] $Description,
        [int] $PictureID,
        [bool] $Supress = $false
    )
    $Paragraph = Remove-WordPicture -WordDocument $WordDocument -Paragraph $Paragraph -PictureID $PictureID -Supress $Supress
    $data = Add-WordPicture -WordDocument $WordDocument -Paragraph $Paragraph `
        -Picture $Picture `
        -ImagePath $ImagePath -ImageWidth $ImageWidth -ImageHeight $ImageHeight `
        -Rotation $Rotation -FlipHorizontal:$FlipHorizontal -FlipVertical:$FlipVertical -Supress $Supress

    if ($Supress) { return } else { return $data }
}