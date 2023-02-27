extends RefCounted
class_name InternetAddress

var address: String = ""
var personal: String = ""

func _init(address: String, personal: String = "") -> void:
    self.address = address
    self.personal = personal

func _to_string() -> String:
    return "%s <%s>" % [personal if not personal.is_empty() else address.split("@")[0], address]
