# NixMan

**NixMan** is a declarative CLI wrapper for the Nix package manager. It is designed for users who want the power of a reproducible package manifest without the overhead of Home Manager or NixOS.

## 🌟 Key Features

* **Search Integration:** Instantly look up package attribute names and descriptions.
* **Declarative Manifest:** Your environment is defined by a single file (`~/.config/nixman/manifest.nix`).
* **Generation Tracking:** View the history of your environment and roll back to any previous state.
* **Garbage Collection:** Keep your `/nix/store` lean with built-in cleaning commands.

## 🚀 Installation

1. Install Nix (Vanilla) on your system.
2. Clone this repo:
```bash
git clone https://github.com/im-BowenGu/Nixman.git
cd Nixman
```
4. Install and make executable:
```bash
sudo cp nixman.sh /usr/local/bin/nixman
sudo chmod +x /usr/local/bin/nixman

```



## ⌨️ Common Commands

| Command | Action |
| --- | --- |
| `nixman search <query>` | Searches nixpkgs for matching names/descriptions. |
| `nixman install <pkg>` | Adds a package to your manifest and triggers a sync. |
| `nixman remove <pkg>` | Deletes a package from the manifest and triggers a sync. |
| `nixman list` | Displays all packages currently in your manifest. |
| `nixman rollback` | Reverts the current user profile to the previous generation. |
| `nixman update` | Updates the nixpkgs channel and syncs the profile. |

---

## 📂 Customizing the Manifest

You can find your manifest at `~/.config/nixman/manifest.nix`. Because this is a standard Nix file, you can organize your packages with comments:

```nixos
with import <nixpkgs> {}; [
  # Development
  neovim
  git
  
  # Communication
  discord
  slack
]

```

After manually editing, simply run `nixman sync` (or `nixman update`) to apply changes.

---
