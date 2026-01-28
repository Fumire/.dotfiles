#!/bin/bash
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

# No .DS_Store creation on external disk
defaults write com.apple.desktopservices DSDontWriteNetworkStores true

# Data format
defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add 1 "yyMMdd"
defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add 2 "yyyyMMdd"
defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add 3 "yyyy-MM-dd"
defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add 2 "yyyy-MM-dd, EEEE"

# Set the time zone
sudo defaults write /Library/Preferences/com.apple.timezone.auto Active -bool YES
# sudo systemsetup -setusingnetworktime on

# Restart automatically if the computer freezes (Error:-99 can be ignored)
sudo systemsetup -setrestartfreeze on 2> /dev/null

# Disable audio feedback when volume is changed
defaults write com.apple.sound.beep.feedback -bool false

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Automatically illuminate built-in MacBook keyboard in low light
defaults write com.apple.BezelServices kDim -bool true

# Turn off keyboard illumination when computer is not used for 5 minutes
defaults write com.apple.BezelServices kDimTime -int 300

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: swipe between pages with three fingers
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.threeFingerHorizSwipeGesture -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true
#
# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true
#
# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true
#
# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Disable hot corners
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-br-corner -int 0

# Don't show recently used applications in the Dock
defaults write com.Apple.Dock show-recents -bool false

# Calendar: Show week numbers (10.8 only)
defaults write com.apple.iCal "Show Week Numbers" -bool true

# Calendar: Week starts on monday
defaults write com.apple.iCal "first day of week" -int 1

###############################################################################
# Kill affected applications                                                  #
###############################################################################

for app in "Address Book" "Calendar" "Contacts" "Dock" "Finder" "Mail" "Safari" "SystemUIServer" "iCal"; do
  killall "${app}" &> /dev/null
done
