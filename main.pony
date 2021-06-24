use "http"
use "net_ssl"
use "json"
use "debug"
use "buffered"

actor Main
  let env: Env
  let token: String = ""
  let roomid: String = ""

  new create(env': Env) =>
    env = env'
    env.out.print("Hello World")

    let doc = JsonDoc
    let obj = JsonObject
    obj.data("msgtype") = "m.text"
    obj.data("body") = "Test message from pony"
    doc.data = obj

    try
      var matrixclient: MatrixClient = MatrixClient(env.root as AmbientAuth, "https://evil.red:8448", token)
      matrixclient.whoami()
    end

  fun gotwhoami() =>
    env.out.print("In gotwhoami")


//    try
//      let url: URL = URL.build("https://evil.red:8448/_matrix/client/r0/rooms/" + roomid + "/send/m.room.message?access_token=" + token)?
//      let pc: MatrixClient = MatrixClient.create(env.root as AmbientAuth, url, doc.string())?
//    else
//      env.out.print("oof")
//    end

actor MatrixClient
  var readerBuffer: Reader ref = Reader
  let auth: AmbientAuth
  let homeserver: String
  let access_token: String
  let sslctx: SSLContext = recover SSLContext.>set_client_verify(false) end
  var httpclient: HTTPClient

  new create(auth': AmbientAuth, homeserver': String, access_token': String) =>
    auth = auth'
    homeserver = homeserver'
    access_token = access_token'

    httpclient = HTTPClient.create(auth)

  be whoami() =>
    try
      let url: URL = URL.build(homeserver + "/_matrix/client/r0/account/whoami?access_token=" + access_token)?
      let req: Payload = Payload.request("GET", url)
      let dumpMaker = recover val NotifyFactory.create(this) end
      let sentreq = httpclient(consume req, dumpMaker)?
    end

  be cancelled() =>
    Debug.out("Cancelled")

  be failed(reason: HTTPFailureReason) =>
    Debug.out("Failed")
		None

  be have_response(response: Payload val) =>
    Debug.out("have_response")
    if (readerBuffer.size() != 0) then
      Debug.out("Buffer should be empty right now - What is going on here...")
      return
    end

    // Print the body if there is any.  This will fail in Chunked or
    // Stream transfer modes.
    try
      let body = response.body()?
      for piece in body.values() do
        readerBuffer.append(piece)
      end
    end

  be have_body(data: ByteSeq val) =>
    readerBuffer.append(data)

  be finished() =>
    let size: USize = readerBuffer.size()
    try
      let block: Array[U8] val = readerBuffer.block(size)?
      let string: String = String.from_array(block)
      Debug.out("finished:" + string)
    end


class NotifyFactory is HandlerFactory
  """
  Create instances of our simple Receive Handler.
  """
  let _main: MatrixClient

  new iso create(main': MatrixClient) =>
    _main = main'

  fun apply(session: HTTPSession): HTTPHandler ref^ =>
    HttpNotify.create(_main, session)

class HttpNotify is HTTPHandler
  """
  Handle the arrival of responses from the HTTP server.  These methods are
  called within the context of the HTTPSession actor.
  """
  let _main: MatrixClient
  let _session: HTTPSession

  new ref create(main': MatrixClient, session: HTTPSession) =>
    _main = main'
    _session = session

  fun ref apply(response: Payload val) =>
    """
    Start receiving a response.  We get the status and headers.  Body data
    *might* be available.
    """
    _main.have_response(response)

  fun ref chunk(data: ByteSeq val) =>
    """
    Receive additional arbitrary-length response body data.
    """
    _main.have_body(data)

  fun ref finished() =>
    """
    This marks the end of the received body data.  We are done with the
    session.
    """
    _main.finished()
    _session.dispose()

  fun ref cancelled() =>
    _main.cancelled()

  fun ref failed(reason: HTTPFailureReason) =>
    _main.failed(reason)



