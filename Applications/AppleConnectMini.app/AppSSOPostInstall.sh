#!/bin/sh

read -r -a APP_SSO_CONTENT <<< `/usr/local/bin/AppSSOTool -c`

LINE_COUNT="${#APP_SSO_CONTENT[@]}"
if [ "3" -eq $LINE_COUNT ]; then
    echo "Installing AppleConnect Mini AppSSO profile..."
    /usr/local/bin/AppSSOTool -l /AppleInternal/Applications/AppleConnectMini.app/AppSSOConfiguration.plist
else
    echo "Some AppSSO profile is already installed. Skipping."
fi
