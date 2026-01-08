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
        
        if ! nix-instantiate --eval -E "with import <nixpkgs> {}; $PKG" &>/dev/null; then
            echo "❌ Package '$PKG' not found in nixpkgs."
            exit 1
        fi

        if grep -qw "$PKG" "$MANIFEST"; then
            echo "ℹ️ '$PKG' is already in the manifest."
            exit 0
        fi

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

        sed -i "/^[[:space:]]*$PKG[[:space:]]*$/d" "$MANIFEST"
        echo "➖ Removed $PKG from manifest."
        sync_profile
        ;;

    "rollback")
        echo "⏳ Rolling back to the previous Nix generation..."
        if nix-env --rollback; then
            echo "✅ Profile rolled back."
            echo "⚠️  Note: Your manifest.nix still contains the newer package list."
            echo "   You may want to manually edit $MANIFEST to match the rollback."
        fi
        ;;

    "list"|"-Q")
        echo "📦 Current Manifested Packages:"
        sed -n '/\[/,/\]/p' "$MANIFEST" | sed '1d;$d' | sed 's/^[[:space:]]*//'
        ;;

    "history")
        nix-env --list-generations
        ;;

    "search"|"-Ss")
        PKG=$2
        [[ -z "$PKG" ]] && echo "Usage: nixman search <pkg>" && exit 1
        nix-env -qaP ".*$PKG.*"
        ;;

    "update"|"upgrade"|"-Syu")
        echo "🌐 Updating nixpkgs channel..."
        nix-channel --update
        sync_profile
        ;;

    "clean")
        echo "🧹 Collecting garbage (removing old generations)..."
        nix-collect-garbage -d
        ;;

    *)
        echo "NixMan - Vanilla Nix Declarative Wrapper"
        echo "Usage:"
        echo "  nixman install <pkg>   (Add package)"
        echo "  nixman remove <pkg>    (Remove package)"
        echo "  nixman rollback        (Revert to previous generation)"
        echo "  nixman history         (Show version history)"
        echo "  nixman list            (List packages)"
        echo "  nixman search <pkg>    (Search nixpkgs)"
        echo "  nixman update          (Update channel and sync)"
        echo "  nixman clean           (Delete old generations)"
        ;;
esac
