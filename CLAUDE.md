# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pansies is a cross-platform PowerShell binary module that provides ANSI escape sequence support, RGB color handling, and rich terminal output capabilities. It's a hybrid C#/.NET + PowerShell module that compiles to a DLL and exposes cmdlets for color manipulation and terminal formatting.

**Key Technologies**: .NET Standard 2.0, PowerShell 5.1+, T4 templating

## Build System

### Using Earthly (Recommended)

Earthly provides containerized, reproducible builds. Requires WSL2 and Docker Desktop on Windows.

```powershell
# Build the module
earthly +build

# Run tests
earthly +test

# Create package
earthly +pack

# Publish (main branch only)
earthly +push
```

Build outputs go to `./Modules/Pansies/`

### Using PowerShell (Alternative)

```powershell
# Install build dependencies first (one-time setup)
Install-Script Install-RequiredModule
Install-RequiredModule

# Build the module
Invoke-Build
# or
./Build.ps1
```

The build process:
1. Compiles C# code via `dotnet publish -c Release -o ./Modules/Pansies/lib`
2. Uses ModuleBuilder to package the PowerShell module
3. Generates external help from `./Docs` folder

## Submodule Management

This project uses a git submodule at `lib/p2f` (a modified version of beefarino's PowerShell provider framework).

```bash
# After cloning
git submodule update --init --recursive

# To update submodule
git submodule update --init --recursive
```

## Architecture

### Module Structure

- **Source/Assembly/** - C# source code for the binary module
  - **Commands/** - Cmdlet implementations (New-Text, Write-Host, Get-Gradient, etc.)
  - **ColorSpaces/** - Color theory implementations (RGB, HSL conversions, comparisons)
  - **Palettes/** - Color palette systems (X11Palette, XTermPalette, ConsolePalette)
  - **Provider/** - PowerShell provider implementation (via p2f submodule)
  - **Colors.cs** & **ColorSpaces.cs** - T4-generated code (from .tt templates)

- **Source/Private/** - PowerShell initialization scripts
  - **_init.ps1** - Module initialization: enables VT processing, registers type accelerators, sets up argument completers

- **Source/Pansies.psd1** - Module manifest
- **Source/Pansies.format.ps1xml** - Custom formatting views

### Key Classes

- `RgbColor` - Core RGB color representation with palette downsampling, color space conversions, and ANSI rendering
- `Text` - Text with foreground/background colors, HTML entity support
- `Gradient` - Color gradient generation between two colors
- `IPalette` / `Palette` - Color palette abstraction for X11, XTerm, and Console colors

### Type Accelerators

Module registers these PowerShell type accelerators on load:
- `[RGBColor]` → `PoshCode.Pansies.RgbColor`
- `[Entities]` → `PoshCode.Pansies.Entities`
- `[ColorCompleterAttribute]` → Custom argument completer (PS7+ only)

### Argument Completion

On module load, RgbColor parameters across all commands automatically get X11 color name completion via an `OnIdle` event handler that registers completers.

## Code Generation

Some C# files are generated from T4 templates:
- `Colors.cs` ← `Colors.tt`
- `ColorSpaces/ColorSpaces.cs` ← `ColorSpaces.tt`

When modifying color definitions or adding color spaces, edit the `.tt` files, not the generated `.cs` files.

## .NET Project Configuration

- **Target**: netstandard2.0 (for cross-platform PowerShell compatibility)
- **Root Namespace**: PoshCode.Pansies
- **Dependencies**:
  - PowerShellStandard.Library 5.1.0 (compile-only, not shipped)
  - p2f submodule projects (bundled in output)
- **NuGet Package**: PoshCode.Pansies (published to NuGet.org)

The csproj includes custom packaging to bundle CodeOwls.PowerShell assemblies from the p2f submodule.

## CI/CD

GitHub Actions workflow (`.github/workflows/build.yaml`):
- **On PR/Push**: Runs `earthly +test`
- **On Main Branch**: Runs `earthly +all` and publishes to PowerShell Gallery and NuGet

Requires secrets: `PSGALLERY_API_KEY`, `NUGET_API_KEY`

## Module Initialization Behavior

When imported, the module:
1. Enables Windows Virtual Terminal processing (on Windows only)
2. Creates/validates `$global:HostPreference` variable
3. Registers metadata converters for RgbColor (if Configuration module present)
4. Registers type accelerators
5. Creates ColorCompleterAttribute type (PS7+ only)
6. Registers RgbColor argument completers for all commands via OnIdle event

## Platform Considerations

- **Windows**: Calls native API to enable VT processing in console
- **Linux/macOS**: Assumes VT support is available
- Color downsampling occurs automatically when terminal doesn't support RGB (falls back to XTerm 256 or ConsoleColor 16)
- Palette detection on Windows reads actual console color configuration

## Versioning

Uses GitVersion for semantic versioning. Version is automatically determined from git tags and branch names during build.
