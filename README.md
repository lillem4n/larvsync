# Larvsync
## http://larvit.se

Sync files automaticly between computers.

The goal is to replace dropbox with an open alternative, where the data always remains yours.

### Requirements
* git

### Install instructions (For Mac OSX and Linux)
* Copy git-merge-newest and git-auto-sync to a place in your $PATH (for example /usr/bin)

    sudo cp git-merge-newest /usr/bin;
    sudo cp git-auto-sync /usr/bin;
 
* Make sure they are executable (chmod a+x <file>)

    sudo chmod a+rx /usr/bin/git-merge-newest /usr/bin/git-auto-sync;
 
* Set up your server with a git repository created with "git init --bare --shared=group"
* **OR** Ask your provider for the correct URL to your server
* Then clone it to your preferred path. In our example we create larvsync on the desktop and have the server URL as larvit.se:/my/shared/larvsync:

    git clone larvit.se:/my/shared/larvsync ~/Desktop/larvsync;

* **IMPORTANT!** Run the following lines from within your newly cloned git repository:

    echo "* merge=newest" > .gitattributes;
    echo -e ".gitattributes\n.gitignore" > .gitignore;
    echo "[merge \"newest\"]" >> .git/config;
    echo -e "\tname = Merge by newest commit" >> .git/config;
    echo -e "\tdriver = git-merge-newest %O %A %B" >> .git/config;

* To have it sync, run this script. You can put it in your auto-start if you dont want to do this each time.

    cd ~/Desktop/larvsync; git-auto-sync;


