package main

import (
	"fmt"

	"github.com/spf13/cobra"
)

var Version = "dev"

var rootCmd = &cobra.Command{
	Use:   "goat-admin",
	Short: "Admin CLI for Goat Cache",
	Long:  "set of commands to manage the goat cache",
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Help()
	},
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the version number of Goat Admin",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(Version)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}

func main() {
	rootCmd.Execute()
}
