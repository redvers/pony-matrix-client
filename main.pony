use "http"
use "net_ssl"
use "json"
use "debug"
use "buffered"
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
//      matrixclient.joined_rooms(thistag~gotjr())
//      matrixclient.whoami(thistag~gotwhoami())
      matrixclient.sync(thistag~gotsync())
//      matrixclient.room_send(thistag~gotmisc("room_send"), roomid, "Test message from pony API")
    end


  be gotjr(decoder: DecodeType val, json: String) =>
    try
      let d: Array[String] = (decoder as JoinedRooms val).apply(json)?
      for f in d.values() do
        env.out.print(f)
      end
    else
      env.out.print("Failed in gotjr")
    end

  be gotwhoami(decoder: DecodeType val, json: String) =>
    try
      let uid: String = (decoder as WhoAmI val).apply(json)?
      env.out.print(uid)
    else
      env.out.print("Failed in gotwhoami")
    end

  be gotsync(decoder: DecodeType val, json: String) =>
    try
      (let aliasmap: Map[String, String], let nb: String) = (decoder as MSync val).apply(json)?
      for f in aliasmap.keys() do
        env.out.print(f)
      end
      env.out.print(nb)
    else
      env.out.print("Failed in gotsync")
    end

  be gotmisc(callbackname: String, data: String) =>
    env.out.print(callbackname)

    let doc = JsonDoc
    try
      env.out.print(doc.>parse(data)?.string(where indent="  ", pretty_print=true))
    else
      env.out.print(data)
    end

