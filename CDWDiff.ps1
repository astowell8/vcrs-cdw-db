


#region  ~~  INPUT  ~~

$start_tag = ''
$end_tag = ''

#Git Repo

$path_cdw = '' # Path to git vcrs-cdw-db folder.
$path_dbops = '' 


#endregion

#region  ~~  DIFF  ~~

Clear-Host

# 1. Verify Folders exist
# 2. Verify Tags Exist

git checkout Main
git fetch --tags
git pull

#endregion