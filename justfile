set unstable := true
set shell := ["pwsh", "-nop", "-c"]
set script-interpreter := ["pwsh", "-nop"]

# These are my common paths, used in my shared /Tasks repo
OUTPUT_ROOT := justfile_directory() / "Modules"
TEST_ROOT := justfile_directory() / "tests"
TEMP_ROOT := justfile_directory() / "temp"
# These are my common build args, used in my shared /Tasks repo
MODULE_NAME := "Pansies"
CONFIGURATION := "Release"

rebuild-dlls: clean build-dlls

[script]
clean:
    $items = Get-Item obj,bin -EA Ignore
    if ($items.count) { rm -r $items }

[script]
build-dlls:
    dotnet build ./Pansies.csproj
    dotnet build ./Pansies.Completion.csproj

# Smoke test: verify the locally-built Pansies module loads in both pwsh and powershell, log timing comparison to baseline
[script]
smoketest:
    $command = @'
        $time = Measure-Command { Import-Module {{justfile_directory()}}\Source\Pansies.psd1 -ErrorAction Stop }
        Write-Host "pwsh: Module loaded successfully in $($time.totalmilliseconds)ms" -ForegroundColor Green
        Get-Module Pansies | Format-List Name,Version,Path
    '@
    $baselinecommand = @'
        $time = Measure-Command { Import-Module Pansies -ErrorAction Stop }
        Write-Host "pwsh: Module loaded successfully in $($time.totalmilliseconds)ms" -ForegroundColor Green
        Get-Module Pansies | Format-List Name,Version,Path
    '@
    mkdir ./Source/lib -EA Ignore
    cp ./bin/Debug/netstandard2.0/*.dll ./Source/lib/
    cp ./bin/Debug/net6.0/Pansies.Completion.dll ./Source/lib/

    echo "Testing local Pansies module load in pwsh..."
    pwsh -NoProfile -Command $command
    echo ""

    echo "Testing baseline Pansies module load in pwsh..."
    pwsh -NoProfile -Command $baselinecommand
    echo ""

    echo "Testing Pansies module load in powershell..."
    powershell -NoProfile -Command $command
    echo ""

    echo "All smoke tests passed!"

# Below were ported from Earthfile

# [script]
# build:
#     echo "Creating output directories..."
#     mkdir {{OUTPUT_ROOT}} {{TEST_ROOT}} {{TEMP_ROOT}}
#     echo "Building module..."
#     # make sure you have bin and obj in .earthlyignore, as their content from context might cause problems
#     pwsh -Command "Invoke-Build -Task Build -File Build.build.ps1"

# [script]
# test: build
#     # If we run a target as a reference in FROM or COPY, its outputs will not be produced
#     echo "Running tests..."
#     # make sure you have bin and obj in .earthlyignore, as their content from context might cause problems
#     pwsh -Command "Invoke-Build -Task Test -File Build.build.ps1"

# [script]
# pack: test
#     # So that we get the module artifact from build too
#     echo "Packing module..."
#     pwsh -Command "Invoke-Build -Task Pack -File Build.build.ps1 -Verbose"

# [script]
# push: pack
#     echo "Publishing module (requires NUGET_API_KEY and PSGALLERY_API_KEY environment variables)..."
#     pwsh -Command "Invoke-Build -Task Push -File Build.build.ps1 -Verbose"

# [script]
# all: test pack push
#     # BUILD +build
#     # BUILD +test
#     # BUILD +pack
#     # BUILD +push
#     echo "All tasks completed!"
