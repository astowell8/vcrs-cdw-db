
#Test
#  1. Between two tags
#  2. Make sure files that were added later aren't include.

Clear-Host

#region  ~~  INPUT  ~~

$start_tag = 'Release_1.0.1'
$end_tag = 'Release_1.0.6'



#Git Repo

$path_cdw = 'C:\Git\vcrs-cdw-db' # Path to git vcrs-cdw-db folder.
$path_dbops = 'C:\Git\vcrs-cdw-dbops' 

$cdw_main = 'Main'
$dbops_main = 'master'
$dbops_release_branch = $( 'Release_' + $start_tag.replace('Release_','') + '_to_' + $end_tag.Replace('Release_','') )

Write-Host $dbops_release_branch
#endregion

#region  ~~  FUNCTION  ~~

#endregion


#region  ~~  DIFF  ~~



#Go to CDW Git Repos
Set-Location $path_cdw

# 1. Verify Folders exist
# 2. Verify Tags Exist

git checkout $cdw_main
git fetch --all --tags
git pull

$diff_files = (git diff --name-only $start_tag $end_tag | ForEach-Object { (Resolve-Path $_).Path})
#$diff_files = (git diff $start_tag $end_tag --name-only)

$diff_hash = @{}
foreach( $File in $diff_files )
{
    $diff_hash.add($file,@{'Start' = $false;'End' = $false})
}

git checkout $start_tag #Detach the repo to the state of starting tag.

foreach($file in $diff_hash.keys){
    write-Host $file
    if(Test-Path $file){ $diff_hash[$file].Start = $true}
}

git checkout $end_tag #Detach the repo to the state of the ending tag.

foreach($file in $diff_hash.keys){
    write-Host $file
    if(Test-Path $file){ $diff_hash[$file].End = $true}
}


Write-Host
Write-Host "Show Diff Files ..."
$diff_files
Write-Host

Set-Location $path_dbops 

git checkout $dbops_main

Get-ChildItem | 
    Where-Object { $_.Name.ToUpper() -notin '.GITHUB', '.GIT' } |
    ForEach-Object {
        Write-Host $("Removing: " + $_.FullName)
        Remove-Item -Path $_.FullName -Recurse -Force
    }    

git add .
git commit -m "Cleared dbops folder"

git branch $dbops_release_branch
git checkout $dbops_release_branch

Set-Location $path_cdw

#Need to copy-item from specific version.

#checkout the files

$diff_files | ForEach-Object {

    $oldfile = Split-Path $_ -Leaf
    $oldpath = (split-path $_ -Parent ) + '\'

    $newfile = $oldfile
    $newpath = $oldpath.replace($path_cdw,$path_dbops)

    #$path = $(Split-Path $olditem  -Parent).replace($path_cdw,$path_dbops)

    Write-Host $( "Working Item:  " + $oldfile )

    write-host "Set-location $oldpath"
    Set-Location $oldpath

    #Git doesn't understand windows path.
    git checkout $start_tag -- $oldfile

    If( -not (Test-Path $newpath )){
        New-Item -ItemType Directory $newpath -Force | Out-Null
    }

    Copy-Item -LiteralPath $($oldpath+$oldfile) -Destination $($newpath+$newitem) -Force | Out-Null

}

Set-Location $path_dbops 

git add .
git commit -m "$start_tag"

Set-Location $path_cdw




#endregion