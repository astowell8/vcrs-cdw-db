#region  ~~  ABOUT  ~~
#
# DEV: Andy Stowell
# DATE: 2025/08/19
#
# PURPOSE:
#   This script will read the local git vcrs-cdw-db repo for changes between two specified release  
#   tags. Then pushes a copy of the added or modified files to the vcrs-cdw-dbops repo for review.
#   A Pull Request is then created showing the changes to those files.
#
#   FYI
#     (!) BEFORE THIS CAN BE RUN, THE GIT REPO MUST BE AT MAIN.
#     (!) BEFORE THIS CAN BE RUN, ALL WORK MUST BE COMMITED OR STASHED.
#
# PREREQUISITE:
#   1. A local git clone of vcrs-cdw-db
#   2. A local git clone of vcrc-cdw-dbops
#   3. Need GitHub CLI installed.
#     Will need to register device with get.
#     run in powershell:   gh auth login --hostname github.com --git-protocol https --web
#     a 8 character code will be returned. 
#
# HOW TO USE:
#   1. Go to the USER INPUT Region.
#   2. Input the starting and ending release tag. ( $start_tag , $end_tag)
#   3. Input the path to the vcrs-cdw-db and vcrs-cdw-dbops git folders.
#   4. Verify the default branch are correct in $cdw_main and $dbops_main. They should be 'main'
#   5. Optional. filter by file extension.

Clear-Host

#endregion

#region  ~~  USER INPUT  ~~


$start_tag = 'release_25.4.0'
$end_tag   = 'release_24.4.7'

#extension filter. semi-colon delimited, include dot (.)
#  only include files with the extension.
#  empty ("") means no filter applied.
$filterStr = ".sql;.ps1"
#$filterStr = ""

$path_cdw   = 'C:\Git\CDW\vcrs-cdw-db' # Path to git vcrs-cdw-db folder.
$path_dbops = 'C:\Git\CDW\vcrs-cdw-dbops' 


$cdw_main = 'main'
$dbops_main = 'main'


$dbops_release_branch = $( 'Release_' + $start_tag.ToUpper().replace('RELEASE_','') + '_to_' + $end_tag.ToUpper().Replace('RELEASE_','') ) #handle case-sensitive.
$dbops_release_content = 'ReleaseContent' # Holds the new/modified files. 

$Head_Sha = ''


#endregion

#region  ~~  CHECK  ~~

if( -not (test-path ($path_cdw + '\.git')))
{
    Write-Host 'CDW-DB Path ($path_cdw) is not a git folder.' -ForegroundColor Red
    Read-Host "Press any key to exit.  "
    exit
}

if( -not (test-path ($path_dbops + '\.git')))
{
    Write-Host 'CDW-DBOPS path ($path_dbops) is not git folder.' -ForegroundColor Red
    Read-Host "Press any key to exit.  "
    exit
}

if(Get-Command gh -ErrorAction SilentlyContinue)
{
    Write-Host "GitHub CLI is Installed."
} else {
    Write-Host "GitHub CLI is NOT installed and is required." -ForegroundColor Red
    Write-Host "  Installed GitHub CLI before rerun this script."
    Read-Host "Press any key to exit.  "
    exit
}

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

function Clear-GitFolder {

#SAFETY. Make sure function always focus on dbops root before clearing.    
Set-Location $path_dbops

Get-ChildItem | 
    Where-Object { $_.Name.ToUpper() -notin '.GITHUB', '.GIT' } |
    ForEach-Object {
        Write-Host $("Removing: " + $_.FullName) -ForegroundColor Cyan
        Remove-Item -Path $_.FullName -Recurse -Force
    }    

git add .
git commit -m "Cleared git folder"

}

#endregion


#region  ~~  SETUP DBOPS REPO  ~~

#If the script has already been run once. Need to clear things.
#  Make sure the branch exists.
set-location $path_dbops

git checkout $dbops_main

#If branch doesn't exists, create it.
if( Check-BranchExists $dbops_release_branch  ){
    git checkout $dbops_release_branch
    Clear-GitFolder
} else {
    git branch $dbops_release_branch
}

git checkout $dbops_main

if( Check-BranchExists $dbops_release_content  ){
    git checkout $dbops_release_content
    Clear-GitFolder
} else {
    git branch $dbops_release_content
}

git checkout $dbops_main

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

# $diff_files = (git diff $start_tag $end_tag --name-only)
#   We need to identify if the file exists during the starting tag and the ending tag.
#   If not at the starting tag but at the ending tag. NEW FILE
#   If at the starting but not at the ending tag. DELETED FILE. Exclude.

#Filter wanted files. Any file with an extension type not in the list is excluded.
$diff_hash = @{}

if($filterstr -ne ''){
    $filterlist = @( $filterStr -split ';').ToUpper()

    $diff_files | get-item | foreach-object {

        $file = $_

        if($file.extension.ToUpper() -in $filterlist)
        {
            #Write-Host ( "Include File:  " + $file.FullName )
            $diff_hash.add(($file.FullName).ToString() ,@{'Start' = $false;'End' = $false})
        } else {
            Write-Host ( "Exclude File:  " + $file.FullName ) -ForegroundColor Cyan
        }
    }
} else {

    Write-Host "No Filter Applied." -ForegroundColor Cyan
    #Filter not used.
    foreach( $file in $diff_files )
    {
        $diff_hash.add($file,@{'Start' = $false;'End' = $false})
    }
   
}

git checkout $start_tag #Detach the repo to the state of starting tag.

foreach($file in $diff_hash.keys){
    write-Host $file -ForegroundColor Cyan
    if(Test-Path $file){ $diff_hash[$file].Start = $true}
}

git checkout $end_tag #Detach the repo to the state of the ending tag.

foreach($file in $diff_hash.keys){
    write-Host $file -ForegroundColor Cyan
    if(Test-Path $file){ $diff_hash[$file].End = $true}
}

#Reattach back to HEAD
git checkout main

Write-Host
Write-Host "Show Diff Files ..." -ForegroundColor Cyan
$diff_files
Write-Host

Set-Location $path_dbops 

git checkout $dbops_main

clear-gitfolder

#Get-ChildItem | 
#    Where-Object { $_.Name.ToUpper() -notin '.GITHUB', '.GIT' } |
#    ForEach-Object {
#        Write-Host $("Removing: " + $_.FullName) -ForegroundColor Cyan
#        Remove-Item -Path $_.FullName -Recurse -Force
#    }    
#
#git add .
#git commit -m "Cleared dbops folder"

#If branch doesn't exists, create it.
if( -not ( Check-BranchExists $dbops_release_branch ) ){
    git branch $dbops_release_branch
}

git checkout $dbops_release_branch

Clear-GitFolder

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
            Write-Host ("Not starting file:  " + $filekey) -ForegroundColor Cyan
        }

    } else {
        Write-Host ( "File Excluded:  " + $filekey ) -ForegroundColor Cyan
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

        Write-Host $( "Working Item:  " + $oldfile ) -ForegroundColor Cyan

        #write-host "Set-location $oldpath"
        Set-Location $oldpath

        #Git doesn't understand windows path.
        git checkout $end_tag -- $oldfile

        If( -not (Test-Path $newpath )){
            New-Item -ItemType Directory $newpath -Force | Out-Null
        }

        Copy-Item -LiteralPath $($oldpath+$oldfile) -Destination $($newpath+$newitem) -Force | Out-Null   

    } else {
        Write-Host ( "File Excluded:  " + $filekey ) -ForegroundColor Cyan
    }
}

#ONCE WE ARE Done Copying Files. We want to reattach to HEAD
git checkout $cdw_main

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

#endregion


#region  ~~  GITHUB  ~~

#Must Authenticate GitHub CLI first.

#Create Pull Request.

#gh auth login --hostname github
# --base branchB --> Target branch( branch I want to merge into)
# --head branchA --> source branch(the branch you want to merge from)
# --title and --body are optional ... but useful.

#gh pr create --base branchB --head branchA --title "My PR Title" --body "Details here"

Set-Location $path_dbops 

#Check if a pull request has already been created. If not, create it.
$ExistingPR = @( gh pr list )

if( -not($ExistingPR.Contains($dbops_release_branch))){
    Write-Host "Creating Pull Request [$dbops_release_branch]" -ForegroundColor Cyan
    gh pr create --base $dbops_release_branch --head $dbops_release_content --title "$dbops_release_branch" --body "Diff for $start_tag to $end_tag"
} else {
    Write-Host "Pull Request already exists." -ForegroundColor Cyan
}


#endregion 