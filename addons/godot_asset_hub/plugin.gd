@tool
extends EditorPlugin

const WEBSITE_URL := "https://ampateur.com/"
const INSTALL_URL := "https://ampateur.com/#/install"
const REPOSITORY_URL := "https://github.com/ampateur/godot-asset-hub-plugin"
const ASSET_API_URL := "https://ampateur.com/api/assets/"
const DEFAULT_ASSET_ID := "github-rpg-battle-system"
const TEMP_ZIP_PATH := "user://temp_asset.zip"
const IMPORT_ROOT := "res://addons/imported_assets"

var dock: PanelContainer
var status_label: Label
var asset_id_input: LineEdit
var install_button: Button
var api_request: HTTPRequest
var download_request: HTTPRequest
var progress_timer: Timer
var current_asset: Dictionary = {}
var installing := false

func _enter_tree() -> void:
    dock = PanelContainer.new()
    dock.name = "GodotAssetHubDock"
    dock.custom_minimum_size = Vector2(300, 0)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 10)
    dock.add_child(content)

    var title := Label.new()
    title.text = "GODOT ASSET HUB"
    title.add_theme_font_size_override("font_size", 16)
    content.add_child(title)

    var intro := Label.new()
    intro.text = "Install verified asset packs directly into the current Godot project."
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.modulate = Color(0.65, 0.72, 0.72)
    content.add_child(intro)

    _add_action(content, "Open marketplace", WEBSITE_URL)
    _add_action(content, "Open install guide", INSTALL_URL)
    _add_action(content, "Open GitHub source", REPOSITORY_URL)

    var asset_label := Label.new()
    asset_label.text = "Asset ID"
    content.add_child(asset_label)

    asset_id_input = LineEdit.new()
    asset_id_input.placeholder_text = "github-rpg-battle-system"
    asset_id_input.text = DEFAULT_ASSET_ID
    asset_id_input.tooltip_text = "Use the asset ID from the Ampateur asset URL."
    content.add_child(asset_id_input)

    install_button = Button.new()
    install_button.text = "Install asset to project"
    install_button.pressed.connect(_install_asset_from_input)
    content.add_child(install_button)

    var copy_button := Button.new()
    copy_button.text = "Copy install guide URL"
    copy_button.pressed.connect(_copy_install_url)
    content.add_child(copy_button)

    status_label = Label.new()
    status_label.text = "Ready"
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.modulate = Color(0.45, 0.9, 0.78)
    content.add_child(status_label)

    api_request = HTTPRequest.new()
    api_request.name = "AssetApiRequest"
    api_request.timeout = 30.0
    api_request.request_completed.connect(_on_api_request_completed)
    dock.add_child(api_request)

    download_request = HTTPRequest.new()
    download_request.name = "AssetDownloadRequest"
    download_request.timeout = 120.0
    download_request.request_completed.connect(_on_download_request_completed)
    dock.add_child(download_request)

    progress_timer = Timer.new()
    progress_timer.wait_time = 0.25
    progress_timer.timeout.connect(_update_download_progress)
    dock.add_child(progress_timer)

    add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)

func _exit_tree() -> void:
    if progress_timer:
        progress_timer.stop()
    if dock:
        remove_control_from_docks(dock)
        dock.queue_free()
        dock = null

func _process(_delta: float) -> void:
    if installing:
        _update_download_progress()

func _add_action(parent: VBoxContainer, label: String, url: String) -> void:
    var button := Button.new()
    button.text = label
    button.pressed.connect(func() -> void: OS.shell_open(url))
    parent.add_child(button)

func _copy_install_url() -> void:
    DisplayServer.clipboard_set(INSTALL_URL)
    _set_status("Install guide URL copied")

func _install_asset_from_input() -> void:
    if not asset_id_input:
        return
    var asset_id := asset_id_input.text.strip_edges()
    if asset_id.is_empty():
        _set_status("Enter an asset ID first")
        return
    install_asset(asset_id)

## Public entry point for future asset cards or editor commands.
func install_asset(asset_id: String) -> void:
    if installing:
        _set_status("An installation is already running")
        return
    var clean_id := asset_id.strip_edges()
    if clean_id.is_empty() or clean_id.contains("/") or clean_id.contains("\\"):
        _set_status("Invalid asset ID")
        return
    installing = true
    current_asset = {}
    if install_button:
        install_button.disabled = true
    _set_status("Loading asset metadata...")
    var error := api_request.request(ASSET_API_URL + clean_id.uri_encode())
    if error != OK:
        _finish_install("Could not start metadata request: %s" % error_string(error))

func _on_api_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
        _finish_install("Asset metadata request failed (%s / HTTP %s)" % [result, response_code])
        return

    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if not parsed is Dictionary or not parsed.has("asset"):
        _finish_install("Asset API returned an invalid response")
        return

    current_asset = parsed.asset
    var download_url := str(current_asset.get("downloadUrl", ""))
    if download_url.is_empty() or not download_url.begins_with("https://"):
        _finish_install("This asset does not provide a secure ZIP download URL")
        return

    _set_status("Downloading %s..." % str(current_asset.get("title", "asset")))
    progress_timer.start()
    var error := download_request.request(download_url)
    if error != OK:
        _finish_install("Could not start download: %s" % error_string(error))

func _update_download_progress() -> void:
    if not installing or not download_request:
        return
    var total := download_request.get_body_size()
    var downloaded := download_request.get_downloaded_bytes()
    if total > 0 and downloaded >= 0:
        var percent := int((float(downloaded) / float(total)) * 100.0)
        _set_status("Downloading asset... %d%%" % clampi(percent, 0, 100))
    elif downloaded > 0:
        _set_status("Downloading asset... %d bytes" % downloaded)

func _on_download_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    progress_timer.stop()
    if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
        _finish_install("Asset download failed (%s / HTTP %s)" % [result, response_code])
        return
    if body.is_empty():
        _finish_install("The downloaded ZIP is empty")
        return

    var file := FileAccess.open(TEMP_ZIP_PATH, FileAccess.WRITE)
    if file == null:
        _finish_install("Could not write %s" % TEMP_ZIP_PATH)
        return
    file.store_buffer(body)
    file.close()

    _set_status("Extracting asset files...")
    var error := _extract_asset_zip()
    if error != OK:
        _finish_install("Could not extract asset: %s" % error_string(error))
        return

    EditorInterface.get_resource_filesystem().scan()
    _finish_install("Installed successfully. Godot is scanning the new files.", false)

func _extract_asset_zip() -> Error:
    var reader := ZIPReader.new()
    var open_error := reader.open(TEMP_ZIP_PATH)
    if open_error != OK:
        return open_error

    var asset_id := str(current_asset.get("id", DEFAULT_ASSET_ID))
    var target_root := "%s/%s" % [IMPORT_ROOT, _safe_path_component(asset_id)]
    var archive_subpath := str(current_asset.get("archiveSubpath", "")).strip_edges().trim_suffix("/")
    var root_dir := DirAccess.open("res://")
    if root_dir == null:
        reader.close()
        return ERR_CANT_OPEN
    var make_root_error := root_dir.make_dir_recursive(target_root)
    if make_root_error != OK:
        reader.close()
        return make_root_error

    var extracted := 0
    for raw_entry in reader.get_files():
        var entry := str(raw_entry).replace("\\", "/")
        if entry.ends_with("/"):
            continue
        if not _is_safe_zip_path(entry):
            reader.close()
            return ERR_INVALID_DATA

        var relative_path := entry
        if not archive_subpath.is_empty():
            var marker := archive_subpath + "/"
            var marker_index := entry.find(marker)
            if marker_index < 0:
                continue
            relative_path = entry.substr(marker_index + marker.length())
        if relative_path.is_empty() or not _is_safe_zip_path(relative_path):
            continue

        var destination := "%s/%s" % [target_root, relative_path]
        var destination_dir := destination.get_base_dir()
        var dir_error := root_dir.make_dir_recursive(destination_dir)
        if dir_error != OK:
            reader.close()
            return dir_error
        var output := FileAccess.open(destination, FileAccess.WRITE)
        if output == null:
            reader.close()
            return ERR_CANT_OPEN
        output.store_buffer(reader.read_file(entry))
        output.close()
        extracted += 1

    reader.close()
    if extracted == 0:
        return ERR_FILE_NOT_FOUND
    return OK

func _is_safe_zip_path(path: String) -> bool:
    var normalized := path.simplify_path()
    return not normalized.begins_with("/") and normalized != ".." and not normalized.begins_with("../") and not normalized.contains("/../")

func _safe_path_component(value: String) -> String:
    var result := value.to_lower().replace(" ", "-")
    var safe := ""
    for character in result:
        if character in "abcdefghijklmnopqrstuvwxyz0123456789-_":
            safe += character
    return safe if not safe.is_empty() else "asset"

func _finish_install(message: String, reset_asset: bool = true) -> void:
    installing = false
    progress_timer.stop()
    if install_button:
        install_button.disabled = false
    _set_status(message)
    if reset_asset:
        current_asset = {}

func _set_status(message: String) -> void:
    if status_label:
        status_label.text = message
