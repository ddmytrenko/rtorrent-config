#!/bin/bash

function func_install () {

    var_downloads_dir=$1
    var_git_branch="install_branch_$2"
    var_source_dir="$3"

    # Go to the source dir
    cd $var_source_dir

    # Check for GIT presence
    echo "Checking for GIT..."
    git --version 2>&1 > /dev/null
    if [ $? -eq 0 ]; then
        echo "GIT is already installed: $(git --version)"
    else
        echo "Please install GIT and try again later!"
        return 1
    fi

    echo "[Done]"
    echo

    echo "Handling GIT branches..."
    git checkout master
    git branch -D "$var_git_branch"
    git branch "$var_git_branch"
    git checkout "$var_git_branch"
    echo "[Done]"
    echo

    var_torrents_dir="$var_downloads_dir/torrents"
    var_new_torrents_dir="$var_torrents_dir/new"
    var_session_dir="$var_torrents_dir/.session"

    echo "Ensuring directories structure..."
    echo "[Downloads directory]: $var_downloads_dir"
    echo

    if [ ! -d "$var_downloads_dir" ]; then
        echo "Creating downloads directory: $var_downloads_dir ..."
        mkdir "$var_downloads_dir"
    fi

    if [ ! -d "$var_torrents_dir" ]; then
        echo "Creating torrents directory: $var_torrents_dir ..."
        mkdir "$var_torrents_dir"
    fi

    if [ ! -d "$var_new_torrents_dir" ]; then
        echo "Creating new torrents directory: $var_new_torrents_dir ..."
        mkdir "$var_new_torrents_dir"
    fi

    if [ ! -d "$var_session_dir" ]; then
        echo "Creating session directory: $var_session_dir ..."
        mkdir "$var_session_dir"
    fi

    echo "[Done]"
    echo

    echo "Editing rtorrent.rc configuration file..."
    cfg="rtorrent.rc"
    [[ -f tmp ]] && rm -rfv tmp
    sed -e "s|directory = .*|directory = ${var_torrents_dir}/|" $cfg > tmp && mv tmp $cfg
    sed -e "s|session = .*|session = ${var_session_dir}/|" $cfg > tmp && mv tmp $cfg
    sed -e "s|.*load_start.*|schedule = watch_directory,5,5,load_start=${var_new_torrents_dir}/*.torrent|" $cfg > tmp && mv tmp $cfg
    echo "[Done]"
    echo

    echo "Committing changes..."
    git add rtorrent.rc
    git commit -m "[INSTALL] $(date)"
    echo "[Done]"
    echo

    echo "Linking rtorrent.rc configuration file..."
    [[ -f "${HOME}/.rtorrent.rc" ]] && rm -rfv "${HOME}/.rtorrent.rc"
    ln -sfv "${var_source_dir}/rtorrent.rc" ~/.rtorrent.rc
    echo "[Done]"
    echo

    return 0
}

# Determine script's folder
var_source="${BASH_SOURCE[0]}"
while [ -h "$var_source" ]; do
    # Resolve $var_source until the file is no longer a symlink
    var_dir="$( cd -P "$( dirname "$var_source" )" && pwd )"
    var_source="$(readlink "$var_source")"
    [[ $var_source != /* ]] && var_source="$var_dir/$var_source"
    # if $var_source was a relative symlink, we need to resolve it relative to the path where the
    # symlink file was located
done
var_dir="$( cd -P "$( dirname "$var_source" )" && pwd )"

var_kernel=$(uname)

if [ "$var_kernel" = "Darwin" ]; then
    echo "RUNNING ON MAC OSX"
    echo
    func_install "$HOME/Downloads" "osx" "$var_dir"
elif [ "$var_kernel" = "Linux" ]; then
    echo "RUNNING ON LINUX"
    echo
    func_install "$(xdg-user-dir DOWNLOAD)" "linux" "$var_dir"
else
    echo "UNSUPPORTED SYSTEM"
    echo
fi
