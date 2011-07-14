#!/bin/sh

#if [[ $EUID -ne 0 ]]; then
#   echo "This script must be run as root" 1>&2
#   exit 1
#fi

set -e

if ! grep -q show-assembly-view $HOME/.emacs 
then
    cat emacs_binding.el >> $HOME/.emacs
    echo " - Edited .emacs file successfully ";
else
    echo " - SKIPPED: .emacs already configured";
fi

if [ ! -d $HOME/bin ]; then
    echo " - No bin directory found in $HOME. Creating one now...\n";
    mkdir $HOME/bin
fi

if [ -e $HOME/bin/analyzer.pl ]; then
    echo " - SKIPPED: Script already present in bin directory";
else
    cp analyzer.pl $HOME/bin/analyzer.pl
    chmod 755 $HOME/bin/analyzer.pl
    echo " - Copied analyzer script into $HOME/bin. ";
    echo " ------Installation successful!-------";
fi





