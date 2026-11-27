#!/bin/bash

HOST="$(cat /etc/hostname)"

echo Starting reinitialization of symlinks with GNU Stow...

if [ "${HOST}" == "poseidon" ]; then
	echo "Continuing with desktop reinitialization..."
	stow -t ~ -d ./stow/shared --dotfiles -v --no-folding -D home
	sudo stow -t / -d ./stow/shared --dotfiles -v --no-folding -D root
	stow -t ~ -d ./stow/desktop --dotfiles -v --no-folding -D home
	sudo stow -t / -d ./stow/desktop --dotfiles -v --no-folding -D root
elif [ "${HOST}" == "neptune" ]; then
	echo "Continuing with laptop initialization..."
	stow -t ~ -d ./stow/shared --dotfiles -v --no-folding -D home
	sudo stow -t / -d ./stow/shared --dotfiles -v --no-folding -D root
	stow -t ~ -d ./stow/laptop --dotfiles -v --no-folding -D home
	sudo stow -t / -d ./stow/laptop --dotfiles -v --no-folding -D root
else
	printf "ERROR: hostname does not match with any of the preconfigured\n"
	printf "options. These include: "poseidon" (desktop) and "neptune" (laptop)\n."
	printf "Fix this if you wish to continue running this script.\n"
	exit 1
fi

echo Finished!
