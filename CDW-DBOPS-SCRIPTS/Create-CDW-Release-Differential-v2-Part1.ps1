#region  ~~  ABOUT  ~~
#
# DEV: Andy Stowell
# DATE: 2025/08/19
#
# PURPOSE:
#   This script will read a local instnace of the git vcrs-cdw-db repo. It looks for changes between 
#   two specified release tags. It Then pushes a copy of the added or modified files to the 
#   vcrs-cdw-dbops repo for review. A Pull Request is then created showing the changes to those files.
#
#
# PREREQUISITE:
#   1. A local git clone of [vcrs-cdw-db]
#   2. A local git clone of [vcrs-cdw-dbops]
#   3. Need GitHub CLI installed.
#     Will need to register device with get.
#     run in powershell:   gh auth login --hostname github.com --git-protocol https --web
#     a 8 character code will be returned. 
#
# HOW TO USE:
#
#   FYI
#     (!) BEFORE THIS CAN BE RUN, 
#           a. THE GIT REPO MUST BE SET THE MAIN BRANCH.
#           b. ALL WORK MUST BE COMMITED OR STASHED.
#
#   1. Go to the USER INPUT region (just below) of this script.
#   2. Input the starting and ending release tag. ( $start_tag , $end_tag)
#   3. Input the path to the vcrs-cdw-db and vcrs-cdw-dbops git folders.
#   4. Verify the default branch are correct in $cdw_main and $dbops_main. They should be 'main'
#   5. OPTIONAL. Add a whitelist filter by file extension( i.g. .sql; .ps1; .txt). 
#
#   (!) When running. The script will populate a local copy of the git repo vcrs-cdw-dbops with 
#   the files that have changed between release. files deleted between releases are excluded.
#   The contents of vcrs-cdw-dbops is then pushed to github. A Pull Request is then generated.
#   
# HISTORY:
#   2025-08-19  Andy Stowell  *UL-2125. Created Script.
#

Clear-Host

#endregion

#region  ~~  USER INPUT  ~~

$start_tag = 'release_24.4.4'
$end_tag   = 'release_24.4.5'

#Whitelist extension filter. semi-colon delimited, include dot (.)
#  only include files with the extension.
#  empty ("") means no filter applied.

#$filterStr = ".sql;.ps1"  #Whitelist filter, semi-colon delimited.
$filterStr = ""

$path_cdw   = 'C:\Git\CDW\vcrs-cdw-db' # Path to git vcrs-cdw-db folder.
$path_dbops = 'C:\Git\CDW\vcrs-cdw-dbops' 


$cdw_main = 'main'
$dbops_main = 'main'

#$dbops_release_content = $('Release_'+$end_tag.ToUpper().Replace('RELEASE_','')) # Holds the new/modified files. 

$dbops_release_folder = "Release_" + $start_tag.ToUpper().replace('RELEASE_','') + "-" + $end_tag.ToUpper().replace('RELEASE_','') + ""
$dbops_release_branch = $( 'StartContent_from_' + $start_tag.ToUpper().replace('RELEASE_','') + '_to_' + $end_tag.ToUpper().Replace('RELEASE_','') ) #handle case-sensitive.

$DT_Diff = New-Object System.Data.DataTable
[Void] $DT_Diff.Columns.Add('File',[String])
[Void] $DT_Diff.Columns.Add('Start',[bool])
[Void] $DT_Diff.Columns.Add('End',[bool])

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
    Read-Host  "Press any key to exit.  "
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

# Will delete files, folders in a git subfolder. .\<gitroot>\<subfolder>
function Clear-GitSubFolder {
    param(
        [string] $GitSubFolder
    )

    #SAFETY. Make sure function always focus on dbops root before clearing.    
    Set-Location $GitSubFolder

    Get-ChildItem | 
        Where-Object { $_.Name.ToUpper() -notin '.GITHUB', '.GIT' } |
        ForEach-Object {
            Write-Host $("Removing: " + $_.FullName) -ForegroundColor Cyan
            Remove-Item -Path $_.FullName -Recurse -Force
        }    

    git add .
    git commit -m "Cleared git folder"

}

# Assumes we're in the correct branch.
function Build-GitFileList{
    param(
            [String] $StartTag
          , [String] $EndTag  
          , [String] $FilterString = "" )

    $FileList = @()
    $Filtered_FileList = @()

    #$FileList = (git diff --name-only $StartTag $EndTag | ForEach-Object { (Resolve-Path $_).Path})
    #$FileList = (git diff --name-only $StartTag $EndTag | ForEach-Object { (Resolve-Path $_).Path})

    $FileList = (git diff --name-only $StartTag $EndTag | ForEach-Object { [String](Resolve-Path $_).Path})

    # foreach( $F in (git diff --name-only $StartTag $EndTag | ForEach-Object { [String](Resolve-Path $_).Path}))
    # {
    #     $FileList  += [String] $F.ToString()
    # }


    # Filter out files without a matching extension in the filterlist.    
    if($FilterString -ne ''){

        $FilterList = @( $FilterString -split ';').ToUpper()

        $FileList | get-item | foreach-object {

            $file_fullname = $_.FullName
            $file_obj = $_

            if($file_obj.extension.ToUpper() -in $FilterList)
            {
                $Filtered_FileList += [String]($file_fullname)
            } 
        }

        return $Filtered_FileList
    } else {
        return $FileList
    }  
}

function Build-GitDiffHash{
    param(
         [String[]] $FileList
        ,[String]   $StartTag
        ,[String]   $EndTag
        ,[String]   $MainBranch
    )

    if( $null -ne $Diff_FileHash){
        Remove-Variable Diff_FileHash
    }

    $Diff_FileHash = @{}

    foreach($file in $FileList){
        #Must cast $file as string or lookup in hash will fail.
        $FileNameString = [String]  $file.ToString()
        $Diff_FileHash.add(  $FileNameString , @{'Start' = $false; 'End' = $false} )

        #TEST - DATATABLE
        $NR = $DT_Diff.NewRow()
        $NR["File"] = $file
        $NR["Start"] = $false
        $NR["End"] = $false

        $DT_Diff.Rows.Add($NR)
    }

    git checkout $StartTag #Detach the repo to the state of starting tag.

    foreach($file in $Diff_FileHash.keys){
        if(Test-Path $file){ 
            $Diff_FileHash[$file].Start = $true
        }
    }

    git checkout $EndTag #Detach the repo to the state of the ending tag.

    foreach($file in $Diff_FileHash.keys){
        if(Test-Path $file){
            $Diff_FileHash[$file].End = $true
        }
    }

    #reattach back to HEAD
    git checkout $MainBranch
    
    return $Diff_FileHash
}

# DataTables pass by  reference.
function Build-GitDiffDT{
    param(
         [String[]] $FileList
        ,[String]   $StartTag
        ,[String]   $EndTag
        ,[String]   $MainBranch
    )



    #Iterate through the list of files found by git diff.
    #  detach the repo to the state of the starting and ending flag.
    #  check if the files exists in either state ( starting tag, ending tag).

    foreach($file in $FileList){
        
        $NR = $DT_Diff.NewRow()
        $NR["File"] = $( [String] $file)

        git checkout $StartTag #Detach the repo to the state of starting tag.        

        if(Test-Path $file){
            $NR["Start"] = $true
        } else {
            $NR["Start"] = $false            
        }       

        git checkout $EndTag #Detach the repo to the state of the ending tag.        

        if(Test-Path $file){
            $NR["End"] = $true
        } else {
            $NR["End"] = $false        
        }       

        $DT_Diff.Rows.Add($NR)
    }

    #reattach back to HEAD
    git checkout $MainBranch
    
}


#endregion

#region  ~~  CDW DB  ~~ 

#Setup vcrs-cdw-db git repo.
Set-Location $path_cdw
git checkout $cdw_main
git fetch --all --tags
git pull

$head_sha = (git rev-parse HEAD) #SAFETY. In case I need the HEAD commit SHA later.

$diff_files = Build-GitFileList -StartTag $start_tag -EndTag $end_tag -FilterString $filterStr

Build-GitDiffDT -StartTag $start_tag -EndTag $end_tag -MainBranch $cdw_main -FileList $diff_files

#endregion

#region  ~~  DBOPS  ~~
Set-Location $path_dbops
git checkout $dbops_main

#If release branch is not created ... make it.
if( -not (Check-BranchExists -Branch $dbops_release_branch) ){
    git branch $dbops_release_branch 
}

git checkout $dbops_release_branch 

if( -not (Test-Path $dbops_release_folder)  ){
    New-Item -Path $dbops_release_folder -ItemType Directory -Force
}

Clear-GitSubFolder -GitSubFolder $( $path_dbops + '\'+ $dbops_release_folder )

#endregion

#region  ~~  COPY ITEMS  ~~

Set-location $path_cdw
git checkout $start_tag

$DT_Diff | Out-GridView

# Read-Host "Stop Here"
# Exit

foreach($DiffRow in $DT_Diff)
{

    #Write-Host "HASH KEY"
    #WRite-Host $filekey

    #Write-Host "BOOL"
    #Write-Host $diff_hash[$filekey].Start

    # Tracks if a file existed during the time of the starttag and endtag.
    #   Used for determining  if a file is new or deleted between the tag range.

    [String] $FullName = $DiffRow["File"]
    [bool] $ExistsAtStartTag = $DiffRow["Start"]
    [bool] $ExistsAtEndTag   = $DiffRow["End"]

    Write-Host ("FILE: " + $FullName + " ") -NoNewline -ForegroundColor Cyan
    Write-Host ("START/END: " + $ExistsAtStartTag + "|" + $ExistsAtEndTag ) -ForegroundColor Cyan

    #Read-Host "Step <ENTER>"

    #If the file doesn't exist at the time of  the end tag. The file was deleted. Exclude it.
    if($ExistsAtEndTag){

        $oldfile = Split-Path $FullName -Leaf
        $oldpath = (split-path $FullName -Parent ) + '\'

        $newpath = $oldpath.replace($path_cdw,$path_dbops+'\'+$dbops_release_folder)
        #$newpath = $oldpath.replace($path_cdw, $dbops_release_folder) 

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
            Write-Host ("Not starting file:  " + $FullName) -ForegroundColor Cyan
        }

    } else {
        Write-Host ( "File Excluded:  " + $FullName ) -ForegroundColor Cyan
    }
}



#Commit Files
set-location $path_dbops

git add .
git commit -m "$start_tag"


#If remote branch doesn't exists, set-upstream. otherwise push
if( -not ( Check-BranchExists $('remotes/origin/'+$dbops_release_branch) ) ){
    git push --set-upstream origin $dbops_release_branch
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
    Write-Host "CREATING PULL REQUEST [$dbops_release_branch]" -ForegroundColor Cyan
    gh pr create --base $dbops_main --head $dbops_release_branch --title "Base Release Files - $dbops_release_branch" --body "Establish base release [$start_tag] files in release folder."
} else {
    Write-Host "Pull Request already exists." -ForegroundColor Cyan
}

#endregion 

