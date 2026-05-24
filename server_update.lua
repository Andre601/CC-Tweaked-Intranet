fs.delete("startup.lua")
shell.run("wget https://raw.githubusercontent.com/ArtMinerCZ/CC-Tweaked-Intranet/refs/heads/main/server.lua startup.lua")
shell.run("startup.lua")
