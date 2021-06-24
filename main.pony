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
    try
      var matrixclient: MatrixClient = MatrixClient(env.root as AmbientAuth, "https://evil.red:8448", token)
      var tis: Main tag = this
      matrixclient.whoami(tis~gotwhoami())
//      matrixclient = MatrixClient(env.root as AmbientAuth, "https://evil.red:8448", token)
      matrixclient.room_send(tis~gotroom_send(), roomid, "Test message from pony API")
    end

  be gotwhoami(data: String) =>
    env.out.print("gotwhoami")
    try
      let jsondoc: JsonDoc = JsonDoc.>parse(consume data)?
      let json: JsonObject = jsondoc.data as JsonObject
      let userid: String = json.data("user_id")? as String
      env.out.print("UserID: " + userid)
    end

  be gotroom_send(data: String) =>
    env.out.print("gotroom_send")
    env.out.print(data)
