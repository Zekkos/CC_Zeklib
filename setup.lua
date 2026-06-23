local basalt_cmd = "wget run https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua -f api/basalt"
local pid_cmd = "wget -r https://raw.githubusercontent.com/Zekkos/CC_Zeklib/main/api/"

shell.run(basalt_cmd)
shell.run("cd api")
shell.run(pid_cmd)