#!/bin/bash

HOST="$(cat /etc/hostname)"

echo Starting reinitialization of symlinks with GNU Stow...

if [ "${HOST}" == "poseidon" ]; then
	echo "Continuing with desktop reinitialization..."
	stow -t ~ -d ./shared --dotfiles -v --restow home
	sudo stow -t / -d ./shared --dotfiles -v --restow root
	stow -t ~ -d ./desktop --dotfiles -v --restow home
	sudo stow -t / -d ./desktop --dotfiles -v --restow root
elif [ "${HOST}" == "neptune" ]; then
	echo "Continuing with laptop initialization..."
	stow -t ~ -d ./shared --dotfiles -v --restow home
	sudo stow -t / -d ./shared --dotfiles -v --restow root
	stow -t ~ -d ./laptop --dotfiles -v --restow home
	sudo stow -t / -d ./laptop --dotfiles -v --restow root
else
	printf "ERROR: hostname does not match with any of the preconfigured\n"
	printf "options. These include: "poseidon" (desktop) and "neptune" (laptop)\n."
	printf "Fix this if you wish to continue running this script.\n"
	exit 1
fi

echo Finished!
