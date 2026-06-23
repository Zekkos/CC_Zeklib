local basalt_dir = "basalt"
local basalt_cmd = "wget run https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua -f "
local pid_cmd = "wget https://raw.githubusercontent.com/Zekkos/CC_Zeklib/main/api/pid.lua"

shell.run(basalt_cmd)
shell.run(pid_cmd)