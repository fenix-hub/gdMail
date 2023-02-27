extends RefCounted
class_name SMTPAuthentication

enum Method {
    PLAIN,
    LOGIN
}

var username: String
var password: String
var method: Method

func _init(username: String, password: String, method: Method = Method.LOGIN) -> void:
    self.username = username
    self.password = password
    self.method = method

func encode_username() -> String:
    return Marshalls.utf8_to_base64(username)

func encode_password() -> String:
    return Marshalls.utf8_to_base64(password)
