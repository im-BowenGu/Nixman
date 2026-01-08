#!/bin/bash
# nixman - A declarative wrapper for vanilla Nix profiles

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
    if nix-env -irf "$MANIFEST"; then
        echo "✅ Sync complete."
    else
        echo "❌ Sync failed. Check your manifest for syntax errors."
        exit 1
    fi
}

case "$1" in
    "install"|"add"|"-S")
        PKG=$2
        [[ -z "$PKG" ]] && echo "Usage: nixman install <pkg>" && exit 1
        
        # Validation
        if ! nix-instantiate --eval -E "with import <nixpkgs> {}; $PKG" &>/dev/null; then
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
        # Filters for attribute names and descriptions
        nix-env -qaP ".*$QUERY.*" --description
        ;;

    "rollback")
        echo "⏳ Rolling back to the previous Nix generation..."
        if nix-env --rollback; then
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
        nix-env --list-generations
        ;;

    "update"|"upgrade"|"-Syu")
        echo "🌐 Updating nixpkgs channel..."
        nix-channel --update
        sync_profile
        ;;

    "clean")
        echo "🧹 Removing old generations and running garbage collector..."
        nix-collect-garbage -d
        ;;

    *)
        echo "NixMan - Vanilla Nix Declarative Wrapper"
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
