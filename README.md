# vcrs-cdw-db

Mock Database of the cdw db repo.


Git Checkout Tag v25.4.0

Next determine difference between source and destination tag ( v24.4.7 )

Compare - The files between the two release 
   git diff tag1..tag2
-- Just want sql files. -filter .sql

Intereted in modified files and New Files.

Checkout the latest of the dbops repo. Main branch
Create new local branch ( the name contains both TAGS ) ex 'release_24_4_7_to_25_4_0'

delete all non-esstential content in the folder.

Copy the diff files into the dbops folder.
Maintain folder structure from cdw-db.

open the PR. The PR should contain 
source and tag release tags.

