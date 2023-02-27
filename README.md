# gdMail

Godot Engine 4.x addon to send emails through an SMTP server in a non-blocking way.

## example usage
```gdscript
extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
    var authentication: SMTPAuthentication = SMTPAuthentication.new(
        "<your_mail@provider.com>", "<your_password>"
    )
    var smtp_client: SMTPClient = SMTPClient.new("smtp.gmail.com", 587, true, authentication)
    add_child(smtp_client)
    
    var email: Email = Email.new(
        InternetAddress.new("<your_mail@provider.com>", "<a_name>"),
        [InternetAddress.new("<recipients_mail@provider.com>")],
        "Hello world!",
        "Hello world! This is my first email ever from Godot. Hope you like it!"
    )
    
    smtp_client.send_email(email)
    await smtp_client.email_sent
    print("Email sent!")
```
