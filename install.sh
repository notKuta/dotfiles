#!/bin/bash

HOST="$(cat /etc/hostname)"

echo Starting initialization of symlinks with GNU Stow...

if [ $HOST == "poseidon" ]; then
	echo "Continuing with desktop initialization..."
	stow -t ~ -d ./shared --dotfiles -v home
	sudo stow -t / -d ./shared --dotfiles -v root
	stow -t ~ -d ./desktop --dotfiles -v home
	sudo stow -t / -d ./desktop --dotfiles -v root
else
	echo "Continuing with laptop initialization..."
	stow -t ~ -d ./shared --dotfiles -v home
	sudo stow -t / -d ./shared --dotfiles -v root
	stow -t ~ -d ./laptop --dotfiles -v home
	sudo stow -t / -d ./laptop --dotfiles -v root
fi

echo Finished!
