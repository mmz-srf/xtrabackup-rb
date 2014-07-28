# xtrabackup-rb

Ruby module and command-line wrapper around innobackupex.

## Features
 - Create full backups
 - Create incremental backups
 - Prepare any backup to be restored
 
## Examples

##### Create a full backup:
    $ xtrabackup-rb backup -t full -d /tmp/backup -u root -p 123456789
 
 
##### Create an incremental backup starting from the latest backup found (full or incremental):
    $ xtrabackup-rb backup -t incremental -d /tmp/backup -u root -p 123456789 
You can now create further incremental backups, or continue with a new full backup.


##### Prepare the latest backup to be restored:
    $ xtrabackup-rb prepare -d /tmp/backup -o /tmp/backup/prepared -u root -p 123456789


##### Prepare a specific backup to be restored:
    $ xtrabackup-rb prepare -d /tmp/backup -o /tmp/backup/prepared -b /tmp/backup/inc/2014-07-28_13-52-48 -u root -p 123456789 
 
 
## TODO
 - Cleanup backups functionality
 - List backups or chains of backups
 - Useful tests
 - Make code more Rubyish (this is my first Ruby "project")