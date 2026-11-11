# Godot Asset Hub EditorPlugin

This Godot 4 editor plugin adds a small dock with shortcuts to the live marketplace, the plugin installation guide, and the GitHub repository.

## Install

Copy the `addons/godot_asset_hub` directory into your Godot project's `addons/` directory:

```bash
cp -R godot-asset-hub-plugin/addons/godot_asset_hub /path/to/your-godot-project/addons/
```

Then open **Project → Project Settings → Plugins**, enable **Godot Asset Hub**, and use the dock on the right side of the editor.

The plugin has no runtime dependencies and only opens the public website or writes the installation URL to the editor clipboard.
