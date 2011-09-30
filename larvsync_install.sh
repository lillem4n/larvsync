#!/bin/bash
read -p "Install path [${HOME}/larvsync]: " installpath
read -p "Enter full path of the folder to be synced [${HOME}/Desktop/larvsync_shared]: " syncpath
read -p "Enter server string (username@domain.com NO PATH): " serverstring
read -p "Enter server path: " serverpath

if [ -z "$installpath" ]; then
	installpath="${HOME}/larvsync";
fi

if [ -z "$syncpath" ]; then
	syncpath="${HOME}/Desktop/larvsync_shared";
fi

if [ -z "$serverstring" ]; then
	echo >&2 "Server string is required.";
	failure=true;
fi

if [ -d "$installpath" ]; then
	echo >&2 "Installation directory already exists.";
	failure=true;
fi

if [ -d "$syncpath" ]; then
	echo >&2 "Sync folder already exists.";
	failure=true;
fi

if [ command -v git &>/dev/null ]; then
	echo >&2 "Git is not installed";
	failure=true;
fi

if [ command -v inotifywait &>/dev/null ]; then
	echo >&2 "Inotify tools is not istalled";
	failure=true;
fi

if [ "$failure" = true ]; then
	echo "Aborting.";
	exit 1;
fi

# Fixing DSA keys
dsapath="${HOME}/.ssh/id_dsa.pub";

if [ ! -f $dsapath ]; then
	if ssh-keygen -t dsa -f $HOME/.ssh/id_dsa -N "" &>/dev/null; then
		echo "Generated SSH DSA key pairs";
	else
		echo >&2 "Generating SSH DSA keys failed";
		exit 1;
	fi
fi

if ssh-copy-id -i $dsapath $serverstring &>/dev/null; then
	echo "Copied SSH public key to server";
else
	echo >&2 "Copied SSH public key to server failed";
	exit 1;
fi
# End of fixing DSA keys

# Creating folders and copying files
if mkdir "${installpath}" &>/dev/null; then
	echo "Created installation folder and script files";
	touch "${installpath}/pullscript.sh";
	touch "${installpath}/syncscript.sh";
	echo -e "#!/bin/bash\npwd=\${0:0:\${#0}-13} # Find out the path to this script\n\nif [ ! -z \"\`ps -C \$0 --no-headers -o \"pid,ppid,sid,comm\"|grep -v \"\$\$ \"|grep -v \"<defunct>\"\`\" ]; then\n\t# Script is already running – abort\n\texit 1\nfi\n\nif [ -z \$1 ]\nthen\n\tread -p \"Enter folder name to be synced: \" foldername\nelse\n\tfoldername=\$1\nfi\n\nwhile true; do\n\tcd \$foldername;\n\tif [ ! -f \"\$foldername/.git/index.lock\" ]; then\n\t\t# Check for git lock\n\n\t\twhile [ -f \"\${pwd}locked.lock\" ]; do\n\t\t\t# The other script is doing stuff, hold on a sec\n\t\t\tsleep 1s;\n\t\tdone\n\t\ttouch \"\${pwd}locked.lock\"; # Our turn to do stuff\n\n\t\t# Do git magic\n\t\tgit reset -q --hard HEAD > /dev/null;\n\t\tgit clean -q -f -d > /dev/null;\n\t\tgit pull origin master -q > /dev/null;\n\n\t\trm \"\${pwd}locked.lock\"; # Remove the lock again\n\tfi\n\tsleep 2m;\ndone" > "${installpath}/pullscript.sh";
	echo -e "#!/bin/bash\npwd=\${0:0:\${#0}-13} # Find out the path to this script\n\nif [ ! -z \"\`ps -C \$0 --no-headers -o \"pid,ppid,sid,comm\"|grep -v \"\$\$ \"|grep -v \"<defunct>\"\`\" ]; then\n\t# Script is already running – abort\n\texit 1\nfi\n\nif [ -z \$1 ]; then\n\tread -p \"Enter folder name to be synced: \" foldername\nelse\n\tfoldername=\$1\nfi\n\nwhile true; do\n\n\t# Wait for something to happend in the wathced folder\n\tinotifywait -r -qq -e close_write -e modify -e attrib -e moved_to -e moved_from -e move -e create -e delete \$foldername;\n\tif [ ! -f \"\$foldername/.git/index.lock\" ]; then\n\t\t# Check for git lock\n\n\t\twhile [ -f \"\${pwd}locked.lock\" ]; do\n\t\t\t# The other script is doing stuff, hold on a sec\n\t\t\tsleep 1s;\n\t\tdone\n\t\ttouch \"\${pwd}locked.lock\"; # Our turn to do stuff\n\t\tsleep 10s; # Wait for file transfers and stuff to complete\n\n\t\t# Do git magic\n\t\tcd \$foldername;\n\t\tgit add . > /dev/null;\n\t\tgit commit -q -a -m \"Auto commit\" > /dev/null;\n\t\tgit push --force -q origin master > /dev/null;\n\t\tgit reset -q --hard HEAD > /dev/null;\n\t\tgit clean -q -f -d > /dev/null;\n\t\tgit pull origin master -q > /dev/null;\n\n\t\trm \"\${pwd}locked.lock\"; # Remove the lock again\n\tfi\n\ndone" > "${installpath}/syncscript.sh";
	chmod +x "${installpath}/pullscript.sh";
	chmod +x "${installpath}/syncscript.sh";
else
	echo >&2 "Failed to create installation folder (${installpath})! Aborting.";
	exit 1;
fi

if git clone -q "${serverstring}:${serverpath}" "${syncpath}" &>/dev/null; then
	echo "Created sync folder";
else
	echo >&2 "Failed to create sync folder (${syncpath})! Aborting.";
	rmdir $installationpath;
	exit 1;
fi

echo "Setting up scripts to autostart";
echo -e "\n\n# larvsync personal cloud service scripts\n${installpath}/pullscript.sh ${syncpath} &\n${installpath}/syncscript.sh ${syncpath} &" >> ${HOME}/.bashrc;

echo "Starting scripts";
${installpath}/pullscript.sh $syncpath &
${installpath}/syncscript.sh $syncpath &

echo "Installation successful!"

exit
