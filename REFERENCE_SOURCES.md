# Reference sources

- Godot 4 HTTPRequest: https://docs.godotengine.org/en/stable/classes/class_httprequest.html
  - `request()` starts an HTTP request; `request_completed(result, response_code, headers, body)` returns the binary body as `PackedByteArray`.
- Godot 4 ZIPReader: https://docs.godotengine.org/en/stable/classes/class_zipreader.html
  - `open(path)`, `get_files()`, `read_file(path)`, and `close()` support ZIP extraction.
- Godot 4 EditorInterface: https://docs.godotengine.org/en/stable/classes/class_editorinterface.html
  - `EditorInterface.get_resource_filesystem()` returns the editor filesystem object used by the plugin to call `scan()`.
- GitHub codeload ZIP endpoint used by the current catalog: https://codeload.github.com/sparklinlabs/superpowers-asset-packs/zip/refs/heads/master
  - The plugin uses the API-provided `archiveSubpath` to extract only the selected pack directory.
