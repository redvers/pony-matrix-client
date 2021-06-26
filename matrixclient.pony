use "http"
use "net_ssl"
use "json"
use "debug"
use "buffered"

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

  be rooms_aliases(cb': {(String): None} val, roomid: String) =>
    Debug.out("be joined_rooms: " + (digestof cb').string())
    try
      let url: URL = URL.build(homeserver + "/_matrix/client/r0/rooms/" + roomid + "/aliases?access_token=" + access_token)?
      let req: Payload = Payload.request("GET", url)
      let dumpMaker = recover val NotifyFactory.create(cb') end
      let sentreq = httpclient(consume req, dumpMaker)?
    end

  be joined_rooms(cb': {(String): None} val) =>
    Debug.out("be joined_rooms: " + (digestof cb').string())
    try
      let url: URL = URL.build(homeserver + "/_matrix/client/r0/joined_rooms?access_token=" + access_token)?
      let req: Payload = Payload.request("GET", url)
      let dumpMaker = recover val NotifyFactory.create(cb') end
      let sentreq = httpclient(consume req, dumpMaker)?
    end

  be initial_sync(cb': {(String): None} val) =>
    Debug.out("be initial_sync: " + (digestof cb').string())
    try
      let url: URL = URL.build(homeserver + "/_matrix/client/r0/sync?access_token=" + access_token)?
      let req: Payload = Payload.request("GET", url)
      let dumpMaker = recover val NotifyFactory.create(cb') end
      let sentreq = httpclient(consume req, dumpMaker)?
    end

/* API Call that identifies our Matrix Username for provided token */
  be whoami(cb': {(String): None} val) =>
    Debug.out("be whoami: " + (digestof cb').string())
    try
      let url: URL = URL.build(homeserver + "/_matrix/client/r0/account/whoami?access_token=" + access_token)?
      let req: Payload = Payload.request("GET", url)
      let dumpMaker = recover val NotifyFactory.create(cb') end
      let sentreq = httpclient(consume req, dumpMaker)?
    end

/* Send a message to a room */
  be room_send(cb': {(String): None} val, roomid: String, message: String) =>
    Debug.out("be room_send: " + (digestof cb').string())
    try
      let doc = JsonDoc
      let obj = JsonObject
      obj.data("msgtype") = "m.text"
      obj.data("body") = message
      doc.data = obj

      let url: URL = URL.build(homeserver + "/_matrix/client/r0/rooms/" + roomid + "/send/m.room.message?access_token=" + access_token)?
      let req: Payload = Payload.request("POST", url)
      req.add_chunk(doc.string())
      let dumpMaker = recover val NotifyFactory.create(cb') end
      let sentreq = httpclient(consume req, dumpMaker)?

    end




class NotifyFactory is HandlerFactory
  let cb: {(String): None} val

  new iso create(cb': {(String): None} val) =>
    cb = cb'
    Debug.out("NotifyFactory: " + (digestof cb).string() + " " + (digestof cb').string())

  fun apply(session: HTTPSession): HTTPHandler ref^ =>
    Debug.out("NotifyFactory.apply: " + (digestof cb).string())
    HttpNotify.create(cb, session)

class HttpNotify is HTTPHandler
  let cb: {(String): None} val
  let _session: HTTPSession
  let readerBuffer: Reader ref = Reader

  new ref create(cb': {(String): None} val, session: HTTPSession) =>
    cb = cb'
    Debug.out("HttpNotify: " + (digestof cb).string() + " " + (digestof session).string())
    _session = session

  fun ref apply(response: Payload val) =>
    try
      let body = response.body()?
      for piece in body.values() do
        readerBuffer.append(piece)
      end
    end

  fun ref chunk(data: ByteSeq val) =>
    Debug.out("HttpNotify.chunk: " + (digestof _session).string())
    readerBuffer.append(data)

  fun ref finished() =>
    let size: USize = readerBuffer.size()
      try
        let block: Array[U8] val = readerBuffer.block(size)?
        let string: String = String.from_array(block)
//        Debug.out("ST: " + string)
        _session.dispose()
        Debug.out("HttpNotify.finish: " + (digestof _session).string())
        cb(string)
      end

  fun ref cancelled() =>
    None

  fun ref failed(reason: HTTPFailureReason) =>
    None

