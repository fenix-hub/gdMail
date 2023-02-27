# gdMail

Godot Engine 4.x addon to send emails through an SMTP server in a non-blocking way.

## example usage
```gdscript
extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
    var authentication: SMTPAuthentication = SMTPAuthentication.new(
        "n.santilio97@gmail.com", "yavlydsalbiutbrq"
    )
    var smtp_client: SMTPClient = SMTPClient.new("smtp.gmail.com", 587, true, authentication)
    add_child(smtp_client)
    
    var email: Email = Email.new(
        InternetAddress.new("n.santilio97@gmail.com", "Nicolo from Godot Engine"),
        [InternetAddress.new("nicolo.santilio@outlook.com")],
        "Hello world!",
        "Hello world! This is my first email ever from Godot. Hope you like it!"
    )
    
    smtp_client.send_email(email)
    await smtp_client.email_sent
    print("Email sent!")
```