// Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
//
// This file is part of Zakenak project and is released under the terms of the
// MIT License. See LICENSE file in the project root for full license information.

package banner

import (
	"fmt"
	"os"
	"sync"
)

var (
	// bannerShown отслеживает показ баннера в текущей сессии
	bannerShown = struct {
		zakenak bool
		deploy  bool
		error   bool
		success bool
		sync.Mutex
	}{}
)

// shouldShowBanner проверяет, нужно ли отображать баннеры
func shouldShowBanner() bool {
	return os.Getenv("ZAKENAK_DISABLE_BANNERS") != "true"
}

// PrintZakenak prints the main Zakenak banner
func PrintZakenak() {
	if !shouldShowBanner() {
		return
	}
	bannerShown.Lock()
	defer bannerShown.Unlock()
	if bannerShown.zakenak {
		return
	}
	bannerShown.zakenak = true
	fmt.Print(`
	 ______     _                      _    
	|___  /    | |                    | |   
	   / / __ _| |  _ _   ___     ___ | |  _
	  / / / _` + "`" + ` | |/ / _` + "`" + `||  _ \ / _` + "`" + ` || |/ /
	 / /_| (_| |  < by_Eberil| | (_| ||   < 
	/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

	GPU-Accelerated GitOps Platform v1.3.2
	Kubernetes Native | NVIDIA GPU Support
	`)
}

// PrintError prints the error banner
func PrintError() {
	if !shouldShowBanner() {
		return
	}
	bannerShown.Lock()
	defer bannerShown.Unlock()
	if bannerShown.error {
		return
	}
	bannerShown.error = true
	fmt.Print(`
	 _____                    
	|  ___|                   
	| |__ _ __ _ __ ___  _ __ 
	|  __| '__| '__/ _ \| '__|
	| |__| |  | | | (_) | |   
	\____/_|  |_|  \___/|_|   
	`)
}

// PrintSuccess prints the success banner
func PrintSuccess() {
	if !shouldShowBanner() {
		return
	}
	bannerShown.Lock()
	defer bannerShown.Unlock()
	if bannerShown.success {
		return
	}
	bannerShown.success = true
	fmt.Print(`
	 _____                             
	/  ___|                            
	\ ` + "`" + `--. _   _  ___ ___ ___  ___ ___ 
	 ` + "`" + `--. \ | | |/ __/ __/ _ \/ __/ __|
	/\__/ / |_| | (_| (_|  __/\__ \__ \
	\____/ \__,_|\___\___\___||___/___/
	`)
}

// PrintDeploy prints the deployment banner
func PrintDeploy() {
	if !shouldShowBanner() {
		return
	}
	bannerShown.Lock()
	defer bannerShown.Unlock()
	if bannerShown.deploy {
		return
	}
	bannerShown.deploy = true
	fmt.Print(`
	 _____             _           
	|  __ \           | |          
	| |  | | ___ ___ | | ___  _   _ 
	| |  | |/ _ \ '_ \| |/ _ \| | | |
	| |__| |  __/ |_) | | (_) | |_| |
	|_____/ \___| .__/|_|\___/ \__, |
				| |             __/ |
				|_|            |___/ 
	`)
}