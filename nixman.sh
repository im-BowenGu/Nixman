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
    
    # We wrap the manifest list in a buildEnv. This creates a single managed 
    # environment package. This is necessary to emulate 'nix-env -irf' (replace) 
    # behavior using 'nix profile', so that removed packages are actually cleaned up.
    EXPR="with import <nixpkgs> {}; buildEnv { name = \"nixman-env\"; paths = import $MANIFEST; }"

    # Install the combined environment as a new generation
    if nix profile install --impure --expr "$EXPR"; then
        
        # CLEANUP: Remove older versions of 'nixman-env' to prevent duplication 
        # in the profile list (active duplicate entries).
        
        # 1. List profile, filter for our env name, get column 1 (Index)
        INDICES=$(nix profile list | grep "nixman-env" | awk '{print $1}')
        
        # 2. Count active entries
        COUNT=$(echo "$INDICES" | wc -w)
        
        if [ "$COUNT" -gt 1 ]; then
            # 3. Sort indices numerically and remove the last one (the one we just installed)
            TO_REMOVE=$(echo "$INDICES" | sort -n | head -n -1)
            
            # 4. Remove the old indices
            # We use xargs to pass the list of indices to remove
            echo "$TO_REMOVE" | xargs nix profile remove
            echo "🧹 Removed previous profile generation to maintain state."
        fi
        
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
        # Uses the new 'nix search' command. 
        # Note: This searches the nixpkgs registry.
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
        # 'nix store gc' is the modern replacement
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
