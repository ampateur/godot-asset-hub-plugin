# Godot Asset Hub EditorPlugin

This Godot 4 `@tool` plugin adds a dock with marketplace links and one-click asset installation.

## Install

```bash
cp -R godot-asset-hub-plugin/addons/godot_asset_hub /path/to/your-godot-project/addons/
```

Then open **Project → Project Settings → Plugins**, enable **Godot Asset Hub**, and use the dock on the right side of the editor.

## Install an asset

Enter an asset ID such as `github-rpg-battle-system` and press **Install asset to project**. The plugin fetches the asset metadata from Ampateur, downloads the HTTPS ZIP to `user://temp_asset.zip`, extracts the selected `archiveSubpath` into `res://addons/imported_assets/<asset-id>/`, and calls the Godot resource filesystem scan.

The extractor rejects absolute paths and `..` traversal entries (ZIP Slip protection). It does not execute any downloaded file. Inspect third-party assets before enabling scripts or importing executable content.

The plugin uses the public API at `https://ampateur.com/api/assets/` and has no runtime dependencies outside Godot 4.
