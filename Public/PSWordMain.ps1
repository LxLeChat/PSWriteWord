function New-WordDocument {
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][alias('Path')][string] $FilePath = ''
    )
    $Word = [Xceed.Words.NET.DocX]
    $WordDocument = $Word::Create($FilePath)
    $WordDocument | Add-Member -MemberType NoteProperty -Name FilePath -Value $FilePath
    return $WordDocument
}

function Get-WordDocument {
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][alias('Path')][string] $FilePath
    )
    $Word = [Xceed.Words.NET.DocX]
    if ($FilePath -ne '') {
        if (Test-Path -LiteralPath $FilePath) {
            try {
                $WordDocument = $Word::Load($FilePath)
                $WordDocument | Add-Member -MemberType NoteProperty -Name FilePath -Value $FilePath
            } catch {
                $ErrorMessage = $_.Exception.Message
                Write-Warning "Get-WordDocument - Document: $FilePath Error: $ErrorMessage"
            }
        } else {
            Write-Warning "Get-WordDocument - Document doesn't exists in path $FilePath. Terminating loading word from file."
            return
        }
    }
    return $WordDocument
}

function Merge-WordDocument {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][alias('Path')][string] $FilePath1,
        [alias('Append')][string] $FilePath2,
        [string] $FileOutput,
        [switch] $OpenDocument,
        [bool] $Supress = $false
    )
    $WordDocument1 = Get-WordDocument -FilePath $FilePath1
    $WordDocument2 = Get-WordDocument -FilePath $FilePath2

    $WordDocument1.InsertDocument($WordDocument2, $true)

    $FilePathOutput = Save-WordDocument -WordDocument $WordDocument1 -FilePath $FileOutput -OpenDocument:$OpenDocument
    if ($Supress) { return } else { return $FilePathOutput }
}

function Save-WordDocument {
    [CmdletBinding()]
    param (
        [alias('Document')][parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory = $false)][Xceed.Words.NET.Container]$WordDocument,
        [alias('Path')][string] $FilePath,
        [string] $Language,
        [switch] $KillWord,
        [switch] $OpenDocument,
        [bool] $Supress = $false
    )
    if ($Language) {
        Write-Verbose -Message "Save-WordDocument - Setting Language to $Language"
        $Paragraphs = Get-WordParagraphs -WordDocument $WordDocument
        foreach ($p in $Paragraphs) {
            Set-WordParagraph -Paragraph $p -Language $Language -Supress $True
        }
    }
    if (($KillWord) -and ($FilePath)) {
        $FileName = Split-Path $FilePath -leaf
        #$Process = get-process | Where { $_.MainWindowTitle -like "$FileName*"} | Select-Object id, name, mainwindowtitle | Sort-Object mainwindowtitle
        #$Process.MainWindowTitle
        Write-Verbose -Message "Save-WordDocument - Killing Microsoft Word with text $FileName"
        $Process = Stop-Process -Name "$FileName*" -Confirm:$false -PassThru
        Write-Verbose -Message "Save-WordDocument - Killed Microsoft Word: $FileName"
    }

    ### Saving PART
    if (-not $FilePath) {
        try {
            $FilePath = $WordDocument.FilePath
            Write-Verbose -Message "Save-WordDocument - Saving document (Save: $FilePath)"
            $Data = $WordDocument.Save()
        } catch {
            $ErrorMessage = $_.Exception.Message
            if ($ErrorMessage -like "*The process cannot access the file*because it is being used by another process.*") {
                $FilePath = "$($([System.IO.Path]::GetTempFileName()).Split('.')[0]).docx"
                Write-Warning -Message "Couldn't save file as it was in use. Trying different name $FilePath"
                $Data = $WordDocument.SaveAs($FilePath)
            }
        }
    } else {
        try {
            Write-Verbose "Save-WordDocument - Saving document (Save AS: $FilePath)"
            $Data = $WordDocument.SaveAs($FilePath)
        } catch {
            $ErrorMessage = $_.Exception.Message
            if ($ErrorMessage -like "*The process cannot access the file*because it is being used by another process.*") {
                $FilePath = "$($([System.IO.Path]::GetTempFileName()).Split('.')[0]).docx"
                Write-Warning -Message "Couldn't save file as it was in use. Trying different name $FilePath"
                $Data = $WordDocument.SaveAs($FilePath)
            }
        }
    }
    ### Saving PART

    If ($OpenDocument) {
        if (($FilePath -ne '') -and (Test-Path -LiteralPath $FilePath)) {
            Invoke-Item -Path $FilePath
        } else {
            Write-Warning -Message "Couldn't open file as it doesn't exists - $FilePath"
        }
    }
    if ($Supress) { return } else { return $FilePath }
}