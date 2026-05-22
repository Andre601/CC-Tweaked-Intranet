fs.delete("startup.lua")
shell.run("wget https://raw.githubusercontent.com/ArtMinerCZ/CC-Tweaked-Intranet/refs/heads/main/startup.lua startup.lua")
shell.run("startup.lua")
