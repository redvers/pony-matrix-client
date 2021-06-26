use "http"
use "net_ssl"
use "json"
use "debug"
use "buffered"
use "serialise"
use "collections"

actor Main
  let env: Env
  let token: String = ""
  let roomid: String = ""

  new create(env': Env) =>
    env = env'
    try
      var matrixclient: MatrixClient = MatrixClient(env.root as AmbientAuth, "https://evil.red:8448", token)
      var thistag: Main tag = this
      matrixclient.joined_rooms(thistag~gotjr())
//      matrixclient.initial_sync(thistag~gotmisc("gotmisc"))
//      matrixclient.whoami(thistag~gotwhoami())
//      matrixclient.room_send(thistag~gotmisc("room_send"), roomid, "Test message from pony API")
    end


  be gotjr(decoder: JoinedRooms val, json: String) =>
    let d: Array[String] = decoder.apply(json)
    for f in d.values() do
      env.out.print(f)
    end

  be gotwhoami(data: String) =>
    env.out.print("gotwhoami")
    try
      let jsondoc: JsonDoc = JsonDoc.>parse(consume data)?
      let json: JsonObject = jsondoc.data as JsonObject
      let userid: String = json.data("user_id")? as String
      env.out.print("UserID: " + userid)
    end

//  be gotsync(json: String) =>
//    let doc: JsonDoc = JsonDoc
//    try
//      doc.parse(json)?
//      let jsono: JsonObject = doc.data as JsonObject
//      let roommap: JsonObject = (jsono.data("rooms")? as JsonObject).data("join")? as JsonObject
//      for (f, g) in roommap.data.pairs() do
//        env.out.print(f)
//        let eventlist: Array[JsonType] = (((g as JsonObject).data("state")? as JsonObject).data("events")? as JsonArray).data
//
//        for event in eventlist.values() do
//          try
//            let s: String = (event as JsonObject).data("type")? as String
//            env.out.print(s)
//          else
//            env.out.print("BROKENZ")
//          end
//        end
//      end
//    else
//      env.out.print("oof, I failed in my try")
//    end


  be gotmisc(callbackname: String, data: String) =>
    env.out.print(callbackname)

    let doc = JsonDoc
    try
      env.out.print(doc.>parse(data)?.string(where indent="  ", pretty_print=true))
    else
      env.out.print(data)
    end

