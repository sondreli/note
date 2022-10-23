#!/bin/bash

# Install main executable to ~/bin
cp note.pl6 note
raku_path=$(which raku)
sed -i.bak "s@#\!@#\!$raku_path@g" note

if [ ! -d $HOME/bin ]; then
    mkdir $HOME/bin
fi
mv note $HOME/bin/
rm *.bak

# Install zsh completion script
cp note_completion.zsh _note

if [ ! -d $HOME/.zsh/completion ]; then
    mkdir -p $HOME/.zsh/completion
fi
mv _note $HOME/.zsh/completion/

echo -n 'Create new database? [y/N]: '
read answer

if [ "$answer" == "y" ]; then
    echo 'Installing database.'
    if [ ! -d $HOME/.config/note ]; then
        mkdir -p $HOME/.config/note
    fi
    sqlite3 $HOME/.config/note/note.db < note.sql
fi
