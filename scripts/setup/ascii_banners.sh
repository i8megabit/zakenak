#!/bin/bash
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# This code is free! Share it, spread peace and technology!
# "Because ASCII art makes everything better!"

k8s_banner() {
	echo '  _  _____ ____  '
	echo ' | |/ / _ \___ \ '
	echo ' | ' / (_) |__) |'
	echo ' | . \> _ </ __/ '
	echo ' |_|\_\___/_____|'
	echo '            by @eberil'
	echo ''
	echo 'Starting Zakenak cluster setup...'
}

success_banner() {
	echo ' ____                             _ '
	echo '/ ___|  _   _  ____ ____ ___  __| |'
	echo '\___ \ | | | |/ ___|  __/ _ \/ _  |'
	echo ' ___) || |_| | |__| |  |  __/ (_| |'
	echo '|____/  \__,_|\____|_|  \___|\__,_|'
	echo ''
	echo 'Cluster is ready!'
}

error_banner() {
	echo ' _____ ____  ____   ___  ____  _ '
	echo '| ____|  _ \|  _ \ / _ \|  _ \| |'
	echo '|  _| | |_) | |_) | | | | |_) | |'
	echo '| |___|  _ <|  _ <| |_| |  _ <|_|'
	echo '|_____|_| \_\_| \_\\___/|_| \_(_)'
	echo ''
	echo 'Something went wrong!'
}