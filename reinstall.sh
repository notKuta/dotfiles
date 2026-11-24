#!/bin/bash

HOST="$(cat /etc/hostname)"

echo Starting reinitialization of symlinks with GNU Stow...

if [ $HOST == "poseidon" ]; then
	echo "Continuing with desktop reinitialization..."
	stow -t ~ -d ./shared --dotfiles -v --restow home
	sudo stow -t / -d ./shared --dotfiles -v --restow root
	stow -t ~ -d ./desktop --dotfiles -v --restow home
	sudo stow -t / -d ./desktop --dotfiles -v --restow root
else
	echo "Continuing with laptop initialization..."
	stow -t ~ -d ./shared --dotfiles -v --restow home
	sudo stow -t / -d ./shared --dotfiles -v --restow root
	stow -t ~ -d ./laptop --dotfiles -v --restow home
	sudo stow -t / -d ./laptop --dotfiles -v --restow root
fi

echo Finished!
