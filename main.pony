use "http"
use "net_ssl"
use "json"
use "debug"

actor Main
  let token: String = ""
  let roomid: String = ""

  new create(env: Env) =>
    env.out.print("Hello World")

    let doc = JsonDoc
    let obj = JsonObject
    obj.data("msgtype") = "m.text"
    obj.data("body") = "Test message from pony"
    doc.data = obj

    try
      let url: URL = URL.build("https://evil.red:8448/_matrix/client/r0/rooms/" + roomid + "/send/m.room.message?access_token=" + token)?
      let pc: PostClient = PostClient.create(env.root as AmbientAuth, url, doc.string())?
    else
      env.out.print("oof")
    end

actor PostClient
  new create(auth: AmbientAuth, url: URL, doc: String) =>
    try
      let sslctx =
        recover
          SSLContext
            .>set_client_verify(false)
        end

      let httpclient: HTTPClient = HTTPClient.create(auth)
      let req: Payload = Payload.request("POST", url)
      req.add_chunk(doc.string())

      let dumpMaker = recover val NotifyFactory.create(this) end
      let sentreq = httpclient(consume req, dumpMaker)?

    else
      Debug.out("OOff")
    end

  be cancelled() =>
    Debug.out("Cancelled")

  be failed(reason: HTTPFailureReason) =>
    Debug.out("Failed")
		None

  be have_response(response: Payload val) =>
    // Print the body if there is any.  This will fail in Chunked or
    // Stream transfer modes.
    try
      let body = response.body()?
      for piece in body.values() do
        let s: String val =  piece as String
    		Debug.out("X" + s)
      end
    end

  be have_body(data: ByteSeq val) =>
    try
      let s: String = data as String
      Debug.out("Y" + s)
    end

  be finished() =>
    Debug.out("finished")


class NotifyFactory is HandlerFactory
  """
  Create instances of our simple Receive Handler.
  """
  let _main: PostClient

  new iso create(main': PostClient) =>
    _main = main'

  fun apply(session: HTTPSession): HTTPHandler ref^ =>
    HttpNotify.create(_main, session)

class HttpNotify is HTTPHandler
  """
  Handle the arrival of responses from the HTTP server.  These methods are
  called within the context of the HTTPSession actor.
  """
  let _main: PostClient
  let _session: HTTPSession

  new ref create(main': PostClient, session: HTTPSession) =>
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



