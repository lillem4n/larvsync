# Larvsync
## http://larvit.se

Sync files automaticly between computers.

The goal is to replace dropbox with an open alternative, where the data always remains yours.

### Requirements
* git

### Install instructions
* Copy git-merge-newest and git-auto-sync to a place in your $PATH (for example /usr/bin)
* Make sure they are executable (chmod a+x <file>)
* Set up your server with a git repository created with "git init --bare --shared=group"
* Then clone it to your preferred path. (for example: "git clone larvit.se:/my/shared/larvsync ~/Desktop/larvsync")
* IMPORTANT! Run the following lines from within your newly cloned git repository:

echo "* merge=newest" > .gitattributes;
echo -e ".gitattributes\n.gitignore" > .gitignore;
echo "[merge \"newest\"]" >> .git/config;
echo -e "\tname = Merge by newest commit" >> .git/config;
echo -e "\tdriver = git-merge-newest %O %A %B" >> .git/config;

* To have it sync automaticly, do "cd /my/larvsync/path; git-auto-sync" (You can put this in auto-start, but dont forget the changed dir)


