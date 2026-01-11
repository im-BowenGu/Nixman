#!/bin/bash
# nixman - A declarative wrapper for vanilla Nix profiles (Updated for Nix 2.0+ CLI)

MANIFEST="$HOME/.config/nixman/manifest.nix"
mkdir -p "$(dirname "$MANIFEST")"

# Initialize manifest if it doesn't exist
if [[ ! -f "$MANIFEST" ]]; then
    echo "with import <nixpkgs> {}; [" > "$MANIFEST"
    echo "]" >> "$MANIFEST"
fi

# Function to sync the profile to the manifest
sync_profile() {
    echo "🔄 Syncing Nix profile to manifest..."
    
    # 1. Build the environment first to ensure it is valid.
    # We build into a temporary symlink. This separates the build step from the install step,
    # ensuring we don't break the profile if the download/build fails.
    BUILD_LINK="/tmp/nixman-build-$(date +%s)"
    EXPR="with import <nixpkgs> {}; buildEnv { name = \"nixman-env\"; paths = import $MANIFEST; }"

    # We use 'nix build' (impure) to realize the derivation
    if nix build --impure --expr "$EXPR" --out-link "$BUILD_LINK"; then
        
        # 2. Find existing versions of nixman-env in the profile.
        # We grep for the specific store path format associated with our buildEnv name.
        # This is more robust than parsing column numbers which vary by Nix version.
        # Regex looks for: /nix/store/<hash>-nixman-env
        OLD_PATHS=$(nix profile list | grep -Eo '/nix/store/[a-z0-9]+-nixman-env')
        
        # 3. Remove old versions to prevent file conflicts during install.
        if [[ -n "$OLD_PATHS" ]]; then
            # We iterate over paths and remove them. 
            # We suppress errors (2>/dev/null) in case a path was listed but is already in a weird state.
            echo "$OLD_PATHS" | while read -r path; do
                if [[ -n "$path" ]]; then
                    nix profile remove "$path" 2>/dev/null || true
                fi
            done
        fi

        # 4. Install the new build.
        # We install the store path directly.
        if nix profile install "$BUILD_LINK"; then
            echo "✅ Sync complete."
        else
            echo "❌ Profile install failed."
            exit 1
        fi
        
        # Cleanup the temporary link
        rm -f "$BUILD_LINK"
    else
        echo "❌ Build failed. Check your manifest for syntax errors or invalid package names."
        exit 1
    fi
}

case "$1" in
    "install"|"add"|"-S")
        PKG=$2
        [[ -z "$PKG" ]] && echo "Usage: nixman install <pkg>" && exit 1
        
        # Validation using modern 'nix eval'
        if ! nix eval --impure --expr "with import <nixpkgs> {}; $PKG" &>/dev/null; then
            echo "❌ Package '$PKG' not found in nixpkgs."
            exit 1
        fi

        if grep -qw "$PKG" "$MANIFEST"; then
            echo "ℹ️ '$PKG' is already in the manifest."
            exit 0
        fi

        # Append package before the closing bracket
        sed -i "$ s/]/  $PKG\n]/" "$MANIFEST"
        echo "➕ Added $PKG to manifest."
        sync_profile
        ;;

    "remove"|"uninstall"|"-R")
        PKG=$2
        [[ -z "$PKG" ]] && echo "Usage: nixman remove <pkg>" && exit 1
        
        if ! grep -qw "$PKG" "$MANIFEST"; then
            echo "❌ '$PKG' not found in manifest."
            exit 1
        fi

        # Remove the exact line match
        sed -i "/^[[:space:]]*$PKG[[:space:]]*$/d" "$MANIFEST"
        echo "➖ Removed $PKG from manifest."
        sync_profile
        ;;

    "search"|"-Ss")
        QUERY=$2
        [[ -z "$QUERY" ]] && echo "Usage: nixman search <query>" && exit 1
        echo "🔍 Searching nixpkgs for '$QUERY'..."
        # Modern replacement for nix-env -qaP
        nix search nixpkgs "$QUERY"
        ;;

    "rollback")
        echo "⏳ Rolling back to the previous Nix generation..."
        if nix profile rollback; then
            echo "✅ Profile rolled back."
            echo "⚠️  Reminder: Update $MANIFEST manually if you want this change to be permanent."
        fi
        ;;

    "list"|"-Q")
        echo "📦 Current Manifested Packages:"
        # Grabs everything between the brackets, removes empty lines
        sed -n '/\[/,/\]/p' "$MANIFEST" | sed '1d;$d' | sed 's/^[[:space:]]*//' | grep .
        ;;

    "history")
        nix profile history
        ;;

    "update"|"upgrade"|"-Syu")
        echo "🌐 Updating nixpkgs channel..."
        nix-channel --update
        sync_profile
        ;;

    "clean")
        echo "🧹 Removing old generations and running garbage collector..."
        nix store gc
        ;;

    *)
        echo "NixMan - Vanilla Nix Declarative Wrapper (Modern CLI)"
        echo "Usage:"
        echo "  nixman search <query>  (Find a package)"
        echo "  nixman install <pkg>   (Add to manifest & sync)"
        echo "  nixman remove <pkg>    (Remove from manifest & sync)"
        echo "  nixman rollback        (Revert profile version)"
        echo "  nixman history         (Show generations)"
        echo "  nixman list            (View manifest)"
        echo "  nixman update          (Refresh nixpkgs)"
        echo "  nixman clean           (Free up disk space)"
        ;;
esac
