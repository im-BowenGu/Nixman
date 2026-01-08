# NixMan

**NixMan** is a lightweight, declarative wrapper for the Nix package manager. It brings the predictability of NixOS configuration to any Linux distribution (like Arch) without the complexity of Home Manager.

## 💡 Why use NixMan?

Standard `nix-env -i` commands are imperative—they change your system state but leave no record of why. NixMan maintains a **Manifest File** (`~/.config/nixman/manifest.nix`). Every time you add or remove a package, NixMan updates the manifest and synchronizes your profile.

## 🛠 Features

* **Declarative:** Your package list is stored in a single readable file.
* **Atomic Sync:** If a sync fails, your profile remains in its previous working state.
* **Rollbacks:** Instantly jump back to a previous "generation" of your environment.
* **Clean:** Easily remove old versions and unreferenced packages with the `clean` command.

## 🚀 Installation

1. Ensure `nix` is installed on your system.
2. Clone this repo:
```bash
git clone https://github.com/im-BowenGu/Nixman.git
cd Nixman
```
3. Install it.
```bash
sudo cp nixman.sh /usr/local/bin/nixman
```   
5. make it executable:
```bash
chmod +x nixman.sh
```



## ⌨️ Command Guide

| Command | Description |
| --- | --- |
| `nixman install <pkg>` | Adds a package to your manifest and syncs. |
| `nixman remove <pkg>` | Removes a package from your manifest and syncs. |
| `nixman rollback` | Reverts the current profile to the previous working state. |
| `nixman list` | Lists all packages currently defined in your manifest. |
| `nixman history` | Shows all previous versions (generations) of your environment. |
| `nixman update` | Pulls latest package definitions and refreshes your apps. |
| `nixman clean` | Deletes old generations to save disk space. |

## 📂 The Manifest

Your manifest is located at `~/.config/nixman/manifest.nix`. You can manually edit this file to group packages or add comments, then run `nixman update` to apply the changes.

---
repos at once?**
