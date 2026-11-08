#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${CONFIGURATION:-Release}"
args=(-project CalendarX.xcodeproj -scheme CalendarX -configuration "$configuration"
  -derivedDataPath build/DerivedData -clonedSourcePackagesDirPath build/SourcePackages
  -destination 'platform=macOS')
if [[ -n "${TEAM_ID:-}" ]]; then
  args+=(-allowProvisioningUpdates CODE_SIGN_STYLE=Automatic
    "CODE_SIGN_IDENTITY=Apple Development" "DEVELOPMENT_TEAM=$TEAM_ID")
else
  args+=(CODE_SIGNING_ALLOWED=NO)
fi
xcodebuild "${args[@]}" build
if [[ -z "${TEAM_ID:-}" ]]; then
  echo 'Compiled without signing. To run widgets, select your Apple Development team in Xcode, or rebuild with TEAM_ID=YOUR_TEAM_ID.'
  exit 0
fi
mkdir -p dist
ditto "build/DerivedData/Build/Products/$configuration/AmLich.app" dist/AmLich.app
codesign --verify --deep --strict dist/AmLich.app
ditto -c -k --sequesterRsrc --keepParent dist/AmLich.app dist/AmLich-0.1.0-macOS.zip
printf '\nBuilt: %s/dist/AmLich.app\n' "$PWD"
