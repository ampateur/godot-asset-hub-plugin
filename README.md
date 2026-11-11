# Godot Asset Hub Plugin

A Godot 4 `@tool` editor plugin that links the Godot editor to the Ampateur marketplace and installs asset packs into the current project.

## Install

```bash
git clone https://github.com/ampateur/godot-asset-hub-plugin.git
cp -R godot-asset-hub-plugin/addons/godot_asset_hub /path/to/your-godot-project/addons/
```

Then open **Project → Project Settings → Plugins**, enable **Godot Asset Hub**, and use the dock on the right side of the editor.

## One-click asset install

1. Open the plugin dock.
2. Enter the asset ID from an Ampateur URL, for example `github-rpg-battle-system`.
3. Click **Install asset to project**.
4. The plugin requests metadata from `https://ampateur.com/api/assets/<asset-id>`.
5. It downloads the HTTPS `downloadUrl` into `user://temp_asset.zip`.
6. It extracts only the configured `archiveSubpath` into `res://addons/imported_assets/<asset-id>/`.
7. It rejects unsafe archive paths and calls `EditorInterface.get_resource_filesystem().scan()`.

The current catalog uses GitHub codeload ZIPs. Because GitHub codeload archives the whole source repository, the API also returns `archiveSubpath` so the plugin installs only the selected asset folder. The downloaded archive is temporary and is overwritten on the next installation.

## API contract

`GET https://ampateur.com/api/assets/github-rpg-battle-system` returns the existing asset object plus:

```json
{
  "downloadUrl": "https://codeload.github.com/sparklinlabs/superpowers-asset-packs/zip/refs/heads/master",
  "archiveSubpath": "rpg-battle-system"
}
```

Only HTTPS download URLs are accepted by the editor plugin. Do not place secrets in an asset URL. Public asset ZIPs should be pinned to a release or commit in production instead of an unpinned branch whenever possible.

## Security notes

The plugin does not execute extracted files. It writes binary entries as project files, rejects absolute and parent-traversal paths, and refreshes the Godot filesystem after extraction. Review third-party assets before enabling scripts or importing executable content.

Marketplace: https://ampateur.com/
Install guide: https://ampateur.com/#/install
