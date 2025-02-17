/*
 * Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
 * 
 * This file is part of Ƶakenak™® project.
 * https://github.com/i8megabit/zakenak
 *
 * This program is free software and is released under the terms of the MIT License.
 * See LICENSE.md file in the project root for full license information.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 *
 * TRADEMARK NOTICE:
 * Ƶakenak™® and the Ƶakenak logo are registered trademarks of Mikhail Eberil.
 * All rights reserved. The Ƶakenak trademark and brand may not be used in any way 
 * without express written permission from the trademark owner.
 */

package banner

import "fmt"

// PrintZakenak prints the main Zakenak banner
func PrintZakenak() {
	fmt.Print(`
	 ______     _                      _    
	|___  /    | |                    | |   
	   / / __ _| |  _ _   ___     ___ | |  _
	  / / / _  | |/ / _ ||  _ \ / _  || |/ /
	 / /_| (_| |  < by_Eberil| | (_| ||   < 
	/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\
  
	Should Harbour?	No.
	`)
}

// PrintError prints the error banner
func PrintError() {
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