
#Test
#  1. Between two tags
#  2. Make sure files that were added later aren't include.

# BEFORE THIS CAN BE RUN, THE GIT REPO MUST BE AT MAIN.
# THERE Can't be any inprogress work.

Clear-Host

#region  ~~  INPUT  ~~

$start_tag = 'Release_1.0.1'
$end_tag   = 'Release_1.0.6'



#Git variables

#$path_cdw   = 'C:\Git\vcrs-cdw-db' # Path to git vcrs-cdw-db folder.
#$path_dbops = 'C:\Git\vcrs-cdw-dbops' 

$path_cdw   = 'C:\Git\MockRepo\vcrs-cdw-db' # Path to git vcrs-cdw-db folder.
$path_dbops = 'C:\Git\MockRepo\vcrs-cdw-dbops' 

$cdw_main = 'Main'
$dbops_main = 'Main'
$dbops_release_branch = $( 'Release_' + $start_tag.replace('Release_','') + '_to_' + $end_tag.Replace('Release_','') )
$dbops_release_content = 'ReleaseContent' # Holds the new/modified files. 

$Head_Sha = ''


#endregion

#region  ~~  FUNCTION  ~~

function Check-BranchExists {
    param(
        [String] $Branch
    )

    [bool] $BranchExists = $false

    $BranchList = @(git branch --all).replace('* ','').trim()

    foreach($Item in $BranchList )
    {
        if( $Branch -eq $Item ){ $BranchExists = $true }
    }

    return $BranchExists
}

#endregion


#region  ~~  DIFF  ~~



#Go to CDW Git Repos
Set-Location $path_cdw

# 1. Verify Folders exist
# 2. Verify Tags Exist

git checkout $cdw_main
git fetch --all --tags
git pull

$head_sha = (git rev-parse HEAD)

$diff_files = (git diff --name-only $start_tag $end_tag | ForEach-Object { (Resolve-Path $_).Path})
#$diff_files = (git diff $start_tag $end_tag --name-only)

# We need to identify if the file exists during the starting tag and the ending tag.
# If not at the starting tag but at the ending tag. NEW FILE
# If at the starting but not at the ending tag. DELETED FILE. Exclude.

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

#Reattach back to HEAD
git checkout main

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

#If branch doesn't exists, create it.
if( -not ( Check-BranchExists $dbops_release_branch ) ){
    git branch $dbops_release_branch
}

git checkout $dbops_release_branch

Set-Location $path_cdw

#Need to copy-item from specific version.

#checkout the files
#  filekey - filename andkey
#  HANDLE START TAG CONTENT
foreach($filekey in $diff_hash.Keys)
{
    # Tracks if a file existed during the time of the starttag and endtag.
    #   Used for determining  if a file is new or deleted between the tag range.
    [bool] $ExistsAtStartTag = $diff_hash[$filekey].Start
    [bool] $ExistsAtEndTag   = $diff_hash[$filekey].End

    #If the file doesn't exist at the time of  the end tag. The file was deleted. Exclude it.
    if($ExistsAtEndTag){

        $oldfile = Split-Path $filekey -Leaf
        $oldpath = (split-path $filekey -Parent ) + '\'

        $newfile = $oldfile
        $newpath = $oldpath.replace($path_cdw,$path_dbops)

        #$path = $(Split-Path $olditem  -Parent).replace($path_cdw,$path_dbops)

        if( $ExistsAtStartTag ){

            Write-Host $( "Working Item:  " + $oldfile )

            #write-host "Set-location $oldpath"
            Set-Location $oldpath

            #Git doesn't understand windows path.
            git checkout $start_tag -- $oldfile

            If( -not (Test-Path $newpath )){
                New-Item -ItemType Directory $newpath -Force | Out-Null
            }

            Copy-Item -LiteralPath $($oldpath+$oldfile) -Destination $($newpath+$newitem) -Force | Out-Null      

        } else {
            Write-Host ("Not starting file:  " + $filekey)
        }

    } else {
        Write-Host ( "File Excluded:  " + $filekey )
    }
}

Set-Location $path_dbops 

git add .
git commit -m "$start_tag"

git checkout $dbops_release_branch

#If branch doesn't exists, create it.
if( -not ( Check-BranchExists $dbops_release_content ) ){
    git branch $dbops_release_content
}

git checkout $dbops_release_content

Set-Location $path_cdw

foreach($filekey in $diff_hash.Keys)
{
    # Tracks if a file existed during the time of the starttag and endtag.
    #   Used for determining  if a file is new or deleted between the tag range.
    [bool] $ExistsAtStartTag = $diff_hash[$filekey].Start
    [bool] $ExistsAtEndTag   = $diff_hash[$filekey].End

    #If the file doesn't exist at the time of  the end tag. The file was deleted. Exclude it.
    if($ExistsAtEndTag){

        $oldfile = Split-Path $filekey -Leaf
        $oldpath = (split-path $filekey -Parent ) + '\'

        $newfile = $oldfile
        $newpath = $oldpath.replace($path_cdw,$path_dbops)

        #$path = $(Split-Path $olditem  -Parent).replace($path_cdw,$path_dbops)

        Write-Host $( "Working Item:  " + $oldfile )

        #write-host "Set-location $oldpath"
        Set-Location $oldpath

        #Git doesn't understand windows path.
        git checkout $end_tag -- $oldfile

        If( -not (Test-Path $newpath )){
            New-Item -ItemType Directory $newpath -Force | Out-Null
        }

        Copy-Item -LiteralPath $($oldpath+$oldfile) -Destination $($newpath+$newitem) -Force | Out-Null   

    } else {
        Write-Host ( "File Excluded:  " + $filekey )
    }
}

Set-Location $path_dbops 

git add .
git commit -m "$end_tag"

git checkout $dbops_release_branch

#"remotes/origin/Main"
#"remotes/origin/Release_1.0.1_to_1.0.6"

#If remote branch doesn't exists, set-upstream. otherwise push
if( -not ( Check-BranchExists $('remotes/origin/'+$dbops_release_branch) ) ){
    git push --set-upstream origin $dbops_release_branch
} else {
    git push    
}

git checkout $dbops_release_content

#If remote branch doesn't exists, set-upstream. otherwise push
if( -not ( Check-BranchExists $('remotes/origin/'+$dbops_release_content) ) ){
    git push --set-upstream origin $dbops_release_content
} else {
    git push    
}


<#
$diff_files | ForEach-Object {

    $oldfile = Split-Path $_ -Leaf
    $oldpath = (split-path $_ -Parent ) + '\'

    $newfile = $oldfile
    $newpath = $oldpath.replace($path_cdw,$path_dbops)

    #$path = $(Split-Path $olditem  -Parent).replace($path_cdw,$path_dbops)

    Write-Host $( "Working Item:  " + $oldfile )

    write-host "Set-location $oldpath"
    Set-Location $oldpath

    #LEFT OFF HERE ... Need to cycle through $diff_hash. make sure to exclude removed files.
    #   SEE COMMENTS ABOVE.




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


#>

#endregion