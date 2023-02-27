# gdMail

Godot Engine 4.x addon to send emails through an SMTP server in a non-blocking way.

## example usage
```gdscript
extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
    
    # Create an SMTPAuthentication (if needed)
    var authentication: SMTPAuthentication = SMTPAuthentication.new(
        "<your_mail@provider.com>", "<your_password>"
    )
    
    # Create and instantiate the SMTPClient (example google -> host: "smtp.google.com" port: 587)
    var smtp_client: SMTPClient = SMTPClient.new("<smtp.provider.com>", <smtp_port>, true, authentication)
    add_child(smtp_client)
    
    # Create an Email
    var email: Email = Email.new(
        # Internet Address of the sender
        InternetAddress.new("<your_mail@provider.com>", "<a_name>"),
        # List of internet addresses of recipients
        [InternetAddress.new("<recipients_mail@provider.com>")],    
        # Subject                                 
        "Hello world!",
        # Body
        "Hello world! This is my first email ever from Godot. Hope you like it!"
    )
    
    # Send the email, the main thread won't be blocked
    smtp_client.send_email(email)
    
    # Await for the `result` signal, it returns a Dictionary
    var result: Dictionary = await smtp_client.result
    if result.success:
        print("Email sent!")
    else:
        print("Could not send email ", result.error)
```

### Signals
- `result(Dictionary: { success: bool, error: Dictionary })`
- `email_sent()`
- `error(Dictionary: { error: String, code: int })`
