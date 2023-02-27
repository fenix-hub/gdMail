extends RefCounted
class_name Email

var from: InternetAddress = null
var to: Array[InternetAddress] = []
var subject: String = ""
var body: String = ""

func _init(from: InternetAddress, to: Array[InternetAddress] = [], subject: String = "", body: String = "") -> void:
    set_sender(from)
    set_recipients(to)
    set_body(body)
    set_subject(subject)

func set_sender(from: InternetAddress) -> void:
    self.from = from

func add_recipient(to: InternetAddress) -> void:
    self.to.append(to)

func set_recipients(to: Array[InternetAddress]) -> void:
    self.to = to

func set_subject(subject: String) -> void:
    self.subject = subject

func set_body(body: String) -> void:
    self.body = body

func _to_string() -> String:
    return ("From: %s\nTo: %s\nSubject: %s\n\n%s\n" % [from, ",".join(to), subject, body])

