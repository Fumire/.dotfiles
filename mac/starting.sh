#!/bin/sh
xcode-select --install

# Allow text selection in Quick Look
defaults write com.apple.finder QLEnableTextSelection -bool TRUE

# Quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Check for software updates daily, not weekly
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Showing all filename extenstion in Finder 
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Use column view in all Finder tabs by default
defaults write com.apple.finder FXPreferredViewStyle Clmv

# Do not make .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Enabling UTF-8 ONLY in Terminal
defaults write com.apple.terminal StringEncodings -array 4

# Setting the Pro theme by default in Terminal
defaults write com.apple.Terminal "Default Window Settings" -string "Pro"
defaults write com.apple.Terminal "Startup Window Settings" -string "Pro"

# Setting screenshots location to $HOME/Desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"

# Setting screenshots format to PNG
defaults write com.apple.screencapture type -string "png"

# Enabling debug menu in Safari
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Enabling the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true

# Do not prompt for confirmation before downloading
defaults write org.m0k.transmission DownloadAsk -bool false

# Use 24 Hour instead 12 Hour
defaults write -globaldomain AppleICUForce24HourTime -int 1

# Use "Submarine" warning sounds
defaults write -globaldomain com.apple.sound.beep.sound -string "/System/Library/Sounds/Submarine.aiff"

# Set the Dock size as the smallest
defaults write com.apple.dock tilesize -int 16

# Remove every icon on the Desktop
defaults write com.apple.finder CreateDesktop -bool false

killall Finder
