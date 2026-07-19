#!/usr/bin/env bash

set -euo pipefail

if ! xcode-select -p > /dev/null 2>&1; then
  xcode-select --install
fi

# Allow text selection in Quick Look
defaults write com.apple.finder QLEnableTextSelection -bool true

# Quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Check for software updates daily, not weekly
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Show all filename extensions in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Use list view by default in Finder
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Do not make .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Enabling UTF-8 ONLY in Terminal
defaults write com.apple.terminal StringEncodings -array 4

# Setting the Pro theme by default in Terminal
defaults write com.apple.Terminal "Default Window Settings" -string "Pro"
defaults write com.apple.Terminal "Startup Window Settings" -string "Pro"

# Setting screenshots location to $HOME/Desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"

# Setting screenshots format to PNG
defaults write com.apple.screencapture type -string "png"

# Enable the Develop menu in Safari
defaults write com.apple.Safari.SandboxBroker ShowDevelopMenu -bool true

# Use 24-hour time
defaults write -globaldomain AppleICUForce24HourTime -int 1

# Use "Submarine" warning sounds
defaults write -globaldomain com.apple.sound.beep.sound -string "/System/Library/Sounds/Submarine.aiff"

# Set the Dock size as the smallest
defaults write com.apple.dock tilesize -int 16

# Remove every icon on the Desktop
defaults write com.apple.finder CreateDesktop -bool false

# Date formats
defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add 1 "yyMMdd"
defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add 2 "yyyyMMdd"
defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add 3 "yyyy-MM-dd"
defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add 4 "yyyy-MM-dd, EEEE"

# Set the time zone
sudo defaults write /Library/Preferences/com.apple.timezone.auto Active -bool true
sudo systemsetup -setusingnetworktime on

# Restart automatically if the computer freezes (Error:-99 can be ignored)
sudo systemsetup -setrestartfreeze on 2> /dev/null || true

# Set a fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Trackpad: enable tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: swipe between full-screen applications with three fingers
defaults -currentHost write NSGlobalDomain com.apple.trackpad.threeFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 2

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Disable hot corners
defaults write com.apple.dock wvous-tl-corner -int 1
defaults write com.apple.dock wvous-tr-corner -int 1
defaults write com.apple.dock wvous-bl-corner -int 1
defaults write com.apple.dock wvous-br-corner -int 1

# Don't show recently used applications in the Dock
defaults write com.apple.dock show-recents -bool false

# Calendar: show week numbers
defaults write com.apple.iCal "Show Week Numbers" -bool true

# Calendar: start weeks on Monday
defaults write com.apple.iCal "first day of week" -int 1

###############################################################################
# Kill affected applications                                                  #
###############################################################################

for app in "Calendar" "Contacts" "Dock" "Finder" "Mail" "Safari" "SystemUIServer"; do
  killall "${app}" > /dev/null 2>&1 || true
done
