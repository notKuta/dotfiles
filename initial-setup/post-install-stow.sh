#!/bin/bash

HOST="$(cat /etc/hostname)"

echo Starting initialization of symlinks with GNU Stow...

if [ "${HOST}" == "poseidon" ]; then
	echo "Continuing with desktop initialization..."
	stow -t ~ -d ./shared --dotfiles -v --adopt home
	sudo stow -t / -d ./shared --dotfiles -v --adopt root
	stow -t ~ -d ./desktop --dotfiles -v --adopt home
	sudo stow -t / -d ./desktop --dotfiles -v --adopt root
elif [ "${HOST}" == "neptune" ]; then
	echo "Continuing with laptop initialization..."
	stow -t ~ -d ./shared --dotfiles -v --adopt home
	sudo stow -t / -d ./shared --dotfiles -v --adopt root
	stow -t ~ -d ./laptop --dotfiles -v --adopt home
	sudo stow -t / -d ./laptop --dotfiles -v --adopt root
else
	printf "ERROR: hostname does not match with any of the preconfigured\n"
	printf "options. These include: "poseidon" (desktop) and "neptune" (laptop)\n."
	printf "Fix this if you wish to continue running this script.\n"
	exit 1
fi

# git reset --hard

echo Finished!
