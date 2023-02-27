extends Node
class_name SMTPClient

signal error(error: Dictionary)
signal email_sent()
signal result(content: Dictionary)

enum SessionStatus {
    NONE,
    SERVER_ERROR,
    COMMAND_NOT_SENT,
    COMMAND_REFUSED,
    HELO,
    HELO_ACK,
    EHLO,
    EHLO_ACK,
    MAIL_FROM,
    RCPT_TO,
    DATA,
    DATA_ACK,
    QUIT,
    STARTTLS,
    STARTTLS_ACK,
    AUTH_LOGIN,
    USERNAME,
    PASSWORD,
    AUTHENTICATED
}

var host: String = ""
var port: int = 25
var tls: bool = false
var tls_started: bool = false
var tls_established: bool = false
var authentication: SMTPAuthentication = null

var tls_options: TLSOptions = TLSOptions.client_unsafe()
var tls_client: StreamPeerTLS = StreamPeerTLS.new()
var tcp_client: StreamPeerTCP = StreamPeerTCP.new()

var session_status: SessionStatus = SessionStatus.NONE

var email: Email = null
var to_index: int = 0

func _init(host: String, port: int = 25, tls: bool = false, authentication: SMTPAuthentication = null) -> void:
    self.host = host
    self.port = port
    self.tls = tls
    self.authentication = authentication


# Called when the node enters the scene tree for the first time.
func _ready():
    session_status = SessionStatus.NONE

func send_email(email: Email) -> void:
    self.email = email
    
    var err: Error = tcp_client.connect_to_host(host, port)
    if err != OK:
        printerr("Could not connect!")
        var error_body: Dictionary = { message = "Error connecting to host.", code = err }
        error.emit(error_body)
        result.emit({ success = false, error = error_body })
        set_process(false)
    
    session_status = SessionStatus.HELO
    set_process(true)

func poll_client() -> Error:
    if tls_started or tls_established:
        tls_client.poll()
        return 0
    else:
        return tcp_client.poll()

func _process(delta: float) -> void:
    if session_status == SessionStatus.SERVER_ERROR:
        close_connection()
    
    if poll_client() == OK:
        var connected: bool = (tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTED if not tls_started else tls_client.get_status() == StreamPeerTLS.STATUS_CONNECTED)
        
        if connected:
            var bytes: int = (tcp_client if not tls_established else tls_client).get_available_bytes()
            
            if bytes > 0:
                var msg: String = (tcp_client if not tls_established else tls_client).get_string(bytes)
                var code: String = msg.left(3)
                match code:
                    "220":
                        match session_status:
                            SessionStatus.HELO:
                                if not write_command("EHLO smtp.godotengine.org"):
                                    return
                                session_status = SessionStatus.EHLO
                            
                            SessionStatus.STARTTLS:
                                var err: Error = tls_client.connect_to_stream(tcp_client, host, tls_options)
                                if err != OK:
                                    session_status = SessionStatus.SERVER_ERROR
                                    var error_body: Dictionary = { message = "Error connecting to TLS Stream.", code = err }
                                    error.emit(error_body)
                                    result.emit({ success = false, error = error_body })
                                    return
                                tls_started = true
                                
                    "250":
                        match session_status:
                            SessionStatus.EHLO:
                                if tls:
                                    if not write_command("STARTTLS"):
                                        return
                                    session_status = SessionStatus.STARTTLS
                                else:
                                    session_status = SessionStatus.EHLO_ACK
                            
                            SessionStatus.STARTTLS:
                                    if not write_command("AUTH LOGIN"):
                                        return
                                    session_status = SessionStatus.AUTH_LOGIN
                            
                            SessionStatus.MAIL_FROM:
                                if not write_command("RCPT TO:<%s>" % email.to[to_index].address):
                                    return
                                session_status = SessionStatus.RCPT_TO
                                to_index += 1
                            
                            SessionStatus.RCPT_TO:
                                if (to_index < email.to.size()):
                                    session_status = SessionStatus.MAIL_FROM
                                    return
                                
                                if not write_command("DATA"):
                                    return
                                session_status = SessionStatus.DATA
                            
                            SessionStatus.DATA_ACK:
                                if not write_command("QUIT"):
                                    return
                                session_status = SessionStatus.QUIT
                    "221":
                        match session_status:
                            SessionStatus.QUIT:
                                close_connection()
                                email_sent.emit()
                                result.emit({ success = true })
                    "235": # Authentication Succeeded
                        match session_status:
                            SessionStatus.PASSWORD:
                                session_status = SessionStatus.AUTHENTICATED
                    "334":
                        match session_status:
                            SessionStatus.AUTH_LOGIN:
                                if msg.begins_with("334 VXNlcm5hbWU6"):
                                    if not write_command(authentication.encode_username()):
                                        return
                                    session_status = SessionStatus.USERNAME
                            
                            SessionStatus.USERNAME:
                                if msg.begins_with("334 UGFzc3dvcmQ6"):
                                    if not write_command(authentication.encode_password()):
                                        return
                                    session_status = SessionStatus.PASSWORD
                    "354":
                        match session_status:
                            SessionStatus.DATA:
                                if not (write_data(email.to_string()) == OK):
                                    session_status = SessionStatus.SERVER_ERROR
                                    return
                                session_status = SessionStatus.DATA_ACK
                    _:
                        printerr(msg)
            else:
                if tls_started and not tls_established:
                    tls_established = true                      
                    if not write_command("EHLO smtp.godotengine.org"):
                        return
        
        if email != null and (session_status == SessionStatus.EHLO_ACK or session_status == SessionStatus.AUTHENTICATED):
            session_status = SessionStatus.MAIL_FROM
            if not write_command("MAIL FROM:<%s>" % email.from.address):
                return
        
        else:
            return
    else:
        printerr("Couldn't poll!")

func write_command(command: String) -> bool:
    var err: Error = (tls_client if tls_established else tcp_client).put_data((command + "\n").to_utf8_buffer())
    if err != OK:
        session_status = SessionStatus.COMMAND_NOT_SENT
        var error_body: Dictionary = { message = "Session error on command: %s" % command, code = err }
        error.emit(error_body)
        result.emit({ success = false, error = error_body })
    return (err == OK)
        

func write_data(data: String) -> Error:
    return (tls_client if tls_established else tcp_client).put_data((data + "\r\n.\r\n").to_utf8_buffer())

func close_connection() -> void:
    session_status = SessionStatus.NONE
    tls_client.disconnect_from_stream()
    tcp_client.disconnect_from_host()
    email = null
    to_index = 0
    tls_started = false
    tls_established = false
    set_process(false)
