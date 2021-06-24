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
      var tis: Main tag = this
      matrixclient.whoami(tis~gotwhoami())
    end

  be gotwhoami(data: String) =>
    env.out.print("In gotwhoami" + data)

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


/* API Call that identifies our Matrix Username for provided token */
  be whoami(cb': {(String): None} val) =>
    try
      let url: URL = URL.build(homeserver + "/_matrix/client/r0/account/whoami?access_token=" + access_token)?
      let req: Payload = Payload.request("GET", url)
      let dumpMaker = recover val NotifyFactory.create(cb') end
      let sentreq = httpclient(consume req, dumpMaker)?
    end


class NotifyFactory is HandlerFactory
  let cb: {(String): None} val

  new iso create(cb': {(String): None} val) =>
    cb = cb'

  fun apply(session: HTTPSession): HTTPHandler ref^ =>
    HttpNotify.create(cb, session)

class HttpNotify is HTTPHandler
  let cb: {(String): None} val
  let _session: HTTPSession
  let readerBuffer: Reader ref = Reader

  new ref create(cb': {(String): None} val, session: HTTPSession) =>
    cb = cb'
    _session = session

  fun ref apply(response: Payload val) =>
    try
      let body = response.body()?
      for piece in body.values() do
        readerBuffer.append(piece)
      end
    end

  fun ref chunk(data: ByteSeq val) =>
    readerBuffer.append(data)

  fun ref finished() =>
    let size: USize = readerBuffer.size()
      try
        let block: Array[U8] val = readerBuffer.block(size)?
        let string: String = String.from_array(block)
        cb(string)
      end

  fun ref cancelled() =>
    None

  fun ref failed(reason: HTTPFailureReason) =>
    None

