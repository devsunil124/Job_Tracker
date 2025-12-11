# release.ps1
# Automates the release process for the Flutter app

$pubspecPath = "pubspec.yaml"

# 1. Check if on main branch
$branch = git rev-parse --abbrev-ref HEAD
if ($branch -ne "main") {
    Write-Error "Error: You are on branch '$branch'. Releases can only be created from 'main'."
    exit 1
}

# 2. Check if pubspec.yaml exists
if (-not (Test-Path $pubspecPath)) {
    Write-Error "pubspec.yaml not found!"
    exit 1
}

# 3. Read content
$content = Get-Content $pubspecPath -Raw

# 4. Find version (Matches "version: 1.0.0+1")
if ($content -match "version:\s+(\d+)\.(\d+)\.(\d+)\+(\d+)") {
    $major = $matches[1]
    $minor = $matches[2]
    $patch = $matches[3]
    $build = $matches[4]

    # 5. Increment version (Patch + Build)
    $newPatch = [int]$patch + 1
    $newBuild = [int]$build + 1
    
    $newVersion = "$major.$minor.$newPatch+$newBuild"
    $tagName = "v$major.$minor.$newPatch" 

    Write-Host "Current Version: $major.$minor.$patch+$build"
    Write-Host "New Version:     $newVersion"

    # 6. Replace in content
    $newContent = $content -replace "version:\s+\d+\.\d+\.\d+\+\d+", "version: $newVersion"
    Set-Content -Path $pubspecPath -Value $newContent

    # 7. Git Operations
    Write-Host "Staging pubspec.yaml..."
    git add pubspec.yaml

    Write-Host "Committing..."
    git commit -m "chore: release $tagName"

    Write-Host "Tagging..."
    git tag -a $tagName -m "Release $tagName"

    Write-Host "Pushing to origin..."
    git push origin main --tags

    # 8. Build APK
    Write-Host "Building APK..."
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Flutter build failed!"
        exit 1
    }

    # 9. Create GitHub Release & Upload APK
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkPath) {
        Write-Host "Uploading to GitHub Releases..."
        # Create release and upload asset. Assuming 'gh' is authenticated.
        gh release create $tagName $apkPath --title "Release $tagName" --notes "Automated release $tagName"
    }
    else {
        Write-Warning "APK not found at $apkPath. Skipping upload."
    }

    Write-Host "Release $tagName completed successfully!"
}
else {
    Write-Error "Could not parse version from pubspec.yaml"
    exit 1
}
