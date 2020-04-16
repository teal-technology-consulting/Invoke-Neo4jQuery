# Invoke-neo4jQuery

<#
    .Synopsis
    Reads CYPHER queries out of an input file, queries Neo4j and exports the results to CSV files.

    .DESCRIPTION
    The script reads one or more CYPHER queries with their titles out of an inpute file. It looks for the file "neo4j_queries.json" in the same directory.
    It then queries the database "neo4j" of a local instance of neo4j by using the credentials "neo4j" and "Bloodhound".
    It creates one CSV file per query with the title as file name in the current directory.
    Database URL, input file name, username, password and output directory can be passed to the script as parameters.
    Be aware that when you have long running queries and you exit the script, the running query will still be executed by neo4j in the background.

    .PARAMETER Uri
    Specifies the API endpoint to use. Usually you only need to change the database name <db name>: http://localhost:7474/db/<db name>/tx/commit"

    .PARAMETER QueryFile
    Specifies which file contains the CYPHER queries. Each query must be in one line and the file must be formatted as a proper json file. You can check that e.g. at https://jsonlint.com/. 

    .PARAMETER User
    Specifies the database user

    .PARAMETER Password
    Specifies the database password

    .PARAMETER OutPath
    Specifies the output path were the CSV files should be created. The script will check if the folder exists but NOT create it. 
    
    .EXAMPLE
    C:\PS> Invoke-neo4jQuery
    
    .EXAMPLE
    C:\PS> Invoke-neo4jQuery "http://localhost:7474/db/bloodhound/tx/commit" queries.json John SuperSecretPassword ".\" -Verbose

#>

[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [URI]$Uri = "http://localhost:7474/db/neo4j/tx/commit",
    
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$QueryFile = "neo4j_queries.json",

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$UserName = "neo4j",

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Password = "Bloodhound",

    [Parameter(Mandatory=$false)]
    [string]$OutPath = ""
)


function Test-OutPath([string]$Path)
{
    if (-not (Test-Path -Path $Path -PathType Container))
    {
        Write-Error "Could not find file `"$Path`"."
        exit 2
    }
    else
    {
        Write-Verbose "Found `"$Path`"."
    }
}

function Test-BinPath([string]$Path)
{
    if (-not (Test-Path -Path $Path -PathType Leaf))
    {
        Write-Error "Could not find file `"$Path`"."
        exit 2
    }
    else
    {
        Write-Verbose "Found `"$Path`"."
    }
}

Write-Verbose "URI: $Uri"
Write-Verbose "Queryfile: $QueryFile"
Write-Verbose "Username: $UserName"
Write-Verbose "Password: $Password"
Write-Verbose "OutPath: $OutPath"

# Function to call Neo4J HTTP EndPoint, Pass in creds & POST JSON Payload
function Invoke-neo4jQuery {
    Param(
        [Parameter(Mandatory=$true,Position=0)][URI]$Uri2,
        [Parameter(Mandatory=$true,Position=1)][System.Management.Automation.PSCredential]$neo4jCreds2,
        [Parameter(Mandatory=$true,Position=2)][string]$Queryname,
        [Parameter(Mandatory=$true,Position=3)][string]$Query2,
        [Parameter(Mandatory=$true,Position=4)][string]$ResultDir2
    )

    $FilePath = $ResultDir2+".\"+$Queryname+".csv"
    Write-Host "Start query `"$Queryname`" at "("{0:dd.MM.yyyy} {0:HH:mm:ss}" -f (Get-Date))
    $Result = Invoke-WebRequest -Uri $Uri2 -Method POST -Body $Query2 -credential $neo4jCreds2 -ContentType "application/json"
    if ($Result) {
        if (Test-Path -Path $FilePath -PathType Leaf) { Remove-Item -Path $FilePath }
        $PsResult = ConvertFrom-Json -InputObject $Result.Content
        $PsResult.results.columns -join ',' | Out-File -FilePath $FilePath
        $PsResult.results.data | ForEach-Object {$_.row -join ','} | Out-File -FilePath $FilePath -Append 
    }
}

#Set pathes
$Path = $PSScriptRoot
$QueryFilePath = Join-Path -Path $Path -ChildPath $QueryFile
$ResultDir = Join-Path -Path $Path -ChildPath $OutPath
Test-OutPath $ResultDir
$ResultDir
Test-BinPath $QueryFilePath


# Create credential object
$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$neo4jCreds = New-Object System.Management.Automation.PSCredential ($UserName, $SecurePassword)


# Load queries from json and call Invoke-neo4jQuery
$json = Get-Content -Raw -Path $QueryFilePath | ConvertFrom-Json
$json.queries | ForEach-Object {
    $temp = $_.query
    $Query=@"
{"statements" : [ {
            "statement" : "$temp"
            } ]
        }
"@
    Invoke-neo4jQuery $Uri $neo4jCreds $_.name $Query $ResultDir
}
