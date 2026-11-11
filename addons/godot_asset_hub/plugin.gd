@tool
extends EditorPlugin

const WEBSITE_URL := "https://ampateur.com/"
const INSTALL_URL := "https://ampateur.com/#/install"
const REPOSITORY_URL := "https://github.com/ampateur/godot-asset-hub-plugin"

var dock: PanelContainer
var status_label: Label

func _enter_tree() -> void:
    dock = PanelContainer.new()
    dock.name = "GodotAssetHubDock"
    dock.custom_minimum_size = Vector2(260, 0)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 10)
    dock.add_child(content)

    var title := Label.new()
    title.text = "GODOT ASSET HUB"
    title.add_theme_font_size_override("font_size", 16)
    content.add_child(title)

    var intro := Label.new()
    intro.text = "Real open-source asset packs and install links for indie developers."
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.modulate = Color(0.65, 0.72, 0.72)
    content.add_child(intro)

    _add_action(content, "Open marketplace", WEBSITE_URL)
    _add_action(content, "Open install guide", INSTALL_URL)
    _add_action(content, "Open GitHub source", REPOSITORY_URL)

    var copy_button := Button.new()
    copy_button.text = "Copy install guide URL"
    copy_button.pressed.connect(_copy_install_url)
    content.add_child(copy_button)

    status_label = Label.new()
    status_label.text = "Ready"
    status_label.modulate = Color(0.45, 0.9, 0.78)
    content.add_child(status_label)

    add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)

func _exit_tree() -> void:
    if dock:
        remove_control_from_docks(dock)
        dock.queue_free()
        dock = null

func _add_action(parent: VBoxContainer, label: String, url: String) -> void:
    var button := Button.new()
    button.text = label
    button.pressed.connect(func() -> void: OS.shell_open(url))
    parent.add_child(button)

func _copy_install_url() -> void:
    DisplayServer.clipboard_set(INSTALL_URL)
    if status_label:
        status_label.text = "Install guide URL copied"
