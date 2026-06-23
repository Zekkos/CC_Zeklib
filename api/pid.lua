PID = {}
PID.__index = PID

function PID:new(kp, ki, kd, setpoint, name, load_config)
    local instance = setmetatable({}, self)
    instance.kp = kp or 0
    instance.ki = ki or 0
    instance.kd = kd or 0
    instance.setpoint = setpoint or 0
    instance.name = name or "PID"
    instance.integral = 0
    instance.output = 0
    instance.last_error = nil
    instance.expandedDisplay = false
    instance.selectedKValue = nil
    instance.stepSize = 0.1
    instance.stepAdjustVisible = false
    if load_config then
        instance:loadConfig()
    else
        instance.savedConfig = {kp = instance.kp, ki = instance.ki, kd = instance.kd}
    end
    return instance
end

function PID:update(measurement, dt)
    dt = dt or 1
    local error = self.setpoint - measurement
    self.integral = self.integral + error * dt
    local derivative = 0
    if self.last_error then
        derivative = (error - self.last_error) / dt
    end
    self.last_error = error

    self.output = self.kp * error + self.ki * self.integral + self.kd * derivative
    return self.output
end

function PID:setSetpoint(setpoint)
    self.setpoint = setpoint
end

function PID:reset()
    self.integral = 0
    self.last_error = nil
end

function PID:saveConfig()
    local config = {
        kp = self.kp,
        ki = self.ki,
        kd = self.kd,
        setpoint = self.setpoint,
        name = self.name
    }
    local file = fs.open(self.name .. "_pid_config.txt", "w")
    file.write(textutils.serialize(config))
    file.close()
    self.savedConfig = {kp = self.kp, ki = self.ki, kd = self.kd}
end

function PID:setKP(kp)
    self.kp = kp
end

function PID:setKI(ki)
    self.ki = ki
end

function PID:setKD(kd)
    self.kd = kd
end

function PID:loadConfig()
    if fs.exists(self.name .. "_pid_config.txt") then
        local file = fs.open(self.name .. "_pid_config.txt", "r")
        local config = textutils.unserialize(file.readAll())
        file.close()
        self.kp = config.kp
        self.ki = config.ki
        self.kd = config.kd
        self.setpoint = config.setpoint
        self.name = config.name or self.name
        self.savedConfig = {kp = self.kp, ki = self.ki, kd = self.kd}
    else
        self.savedConfig = {kp = self.kp, ki = self.ki, kd = self.kd}
    end
end

function PID:restoreSavedValues()
    if self.savedConfig then
        self.kp = self.savedConfig.kp
        self.ki = self.savedConfig.ki
        self.kd = self.savedConfig.kd
    end
    self.selectedKValue = nil
    self.stepAdjustVisible = false
end

function sigfig(num, sig)
    if num == 0 then return 0 end
    local mult = 10^(sig - math.ceil(math.log10(math.abs(num))))
    return math.floor(num * mult + 0.5) / mult
end

function PID:resetButton(butself)
    sleep(0.2)
    butself:setBackground(colors.cyan)
end

function PID:updateLabels()
    self.kp_text:setText("kp:" .. sigfig(self.kp, 5))
    self.ki_text:setText("ki:" .. sigfig(self.ki, 5))
    self.kd_text:setText("kd:" .. sigfig(self.kd, 5))
    self.stepSize_label.text = "Step Size:"..sigfig(self.stepSize, 5)
    self.setpoint_num_label.text = "" .. sigfig(self.setpoint, 5)
    self.output_num_label.text = "" .. sigfig(self.output, 5)
    self.error_num_label.text = "" .. sigfig(self.last_error, 5)

end

function PID:createTab(basalt, tabs)
    local selfRef = self
    selfRef.tab = tabs:newTab(selfRef.name)
    selfRef.scroll = selfRef.tab:addScrollFrame({
        x=1,
        y=1,
        width=tabs.width-tabs.sidebarWidth,
        height=tabs.height,
        background=colors.black
    })


    -- Setup the text displays and buttons for kp ki and kd
    selfRef.kp_text = selfRef.scroll:addTextBox({
        x=2,
        y=2,
        width=10,
        height=1,
        background=colors.lightGray,
        foreground=colors.white
    }):setText("kp:" .. sigfig(selfRef.kp, 5))
    selfRef.ki_text = selfRef.scroll:addTextBox({
        x=2,
        y=4,
        width=10,
        height=1,
        background=colors.lightGray,
        foreground=colors.white
    }):setText("ki:" .. sigfig(selfRef.ki, 5))
    selfRef.kd_text = selfRef.scroll:addTextBox({
        x=2,
        y=6,
        width=10,
        height=1,
        background=colors.lightGray,
        foreground=colors.white
    }):setText("kd:" .. sigfig(selfRef.kd, 5))

    local function subConstant(self, varaibleName)
        self[varaibleName] = self[varaibleName] - self.stepSize
    end
    local function addConstant(self, varaibleName)
        self[varaibleName] = self[varaibleName] + self.stepSize
    end
    local function mult10Constant(self, varaibleName)
        self[varaibleName] = self[varaibleName] * 10
    end
    local function div10Constant(self, varaibleName)
        self[varaibleName] = self[varaibleName] * 10
    end
    local function makeButtonCallback(selfReference, actionFunc)
        return function(varaibleName)
            return function(self, button, x, y)
                actionFunc(selfReference, varaibleName)
                self:setBackground(colors.red)
                selfReference:updateLabels()
                basalt.schedule(
                    function()
                        sleep(0.2)
                        self:setBackground(colors.cyan)
                    end
                )
            end
        end
    end

    local decrement = makeButtonCallback(selfRef, subConstant)
    local increment = makeButtonCallback(selfRef, addConstant)
    

    local function makeIncrementButton(selfReferemce, x, y, variableName)
        return selfReference.scroll:addButton({width=1, height=1})
            :setPosition(x, y)
            :setText("+")
            :setBackground(colors.cyan)
            :setForeground(colors.white)
            :oneClick(increment(variableName))
    end
    local function makeDecrementButton(selfReferemce, x, y, variableName)
        return selfReference.scroll:addButton({width=1, height=1})
            :setPosition(x, y)
            :setText("-")
            :setBackground(colors.cyan)
            :setForeground(colors.white)
            :oneClick(decrement(variableName))
    end

    selfRef.kp_plus = makeIncrementButton(selfRef, 14, 2, "kp")
    selfRef.kp_minus = makeDecrementButton(selfRef, 16, 2, "kp")

    selfRef.ki_plus = makeIncrementButton(selfRef, 14, 4, "ki")
    selfRef.ki_minus = makeDecrementButton(selfRef, 16, 4, "ki")

    selfRef.kd_plus = makeIncrementButton(selfRef, 14, 6, "kd")
    selfRef.kd_minus = makeDecrementButton(selfRef, 16, 6, "kd")
    
    -- Step size things -------------------
    local mult10 = makeButtonCallback(selfRef, mult10Constant)
    local div10 = makeButtonCallback(selfRef, div10Constant)

    selfRef.stepSize_label = selfRef.scroll:addLabel({
        x=18,
        y=2,
        background=colors.lightGray,
        foreground=colors.white,
        text=function()
                return "Step Size:"..sigfig(selfRef.stepSize, 5)
            end
    })

    selfRef.stepsize_plus = selfRef.scroll:addButton({width=3, height=1})
        :setPosition(18, 4)
        :setText("*10")
        :setBackground(colors.cyan)
        :setForeground(colors.white)
        :onClick(mult10("stepSize"))
    selfRef.stepsize_minus = selfRef.scroll:addButton({width=3, height=1})
        :setPosition(22, 4)
        :setText("/10")
        :setBackground(colors.cyan)
        :setForeground(colors.white)
        :onClick(div10("stepSize"))
    
    -- Save/Load

    selfRef.save_button = selfRef.scroll:addButton({width=4, height=1})
        :setPosition(22, 6)
        :setText("Save")
        :setBackground(colors.cyan)
        :setForeground(colors.white)
        :onClick(
            function(self, button, x, y)
                selfRef:saveConfig()
                self:setBackground(colors.red)
                selfRef:updateLabels()
                basalt.schedule(
                    function()
                        sleep(0.2)
                        self:setBackground(colors.cyan)
                    end)
            end)
    
    selfRef.load_button = selfRef.scroll:addButton({width=4, height=1})
        :setPosition(27, 6)
        :setText("Load")
        :setBackground(colors.cyan)
        :setForeground(colors.white)
        :onClick(
            function(self, button, x, y)
                selfRef:loadConfig()
                self:setBackground(colors.red)
                selfRef:updateLabels()
                basalt.schedule(
                    function()
                        sleep(0.2)
                        self:setBackground(colors.cyan)
                    end)
            end)

    -- Display current setpoint, error, and output
    local var_width = 12
    selfRef.setpoint_label = selfRef.scroll:addLabel({
        x = 2,
        y = 8,
        background = colors.lightGray,
        foreground = colors.white,
        width=var_width,
        text = "Stepoint: "
    })
    selfRef.output_label = selfRef.scroll:addLabel({
        x = 2,
        y = 10,
        background = colors.lightGray,
        foreground = colors.white,
        width=var_width,
        text = "Output: "
    })
    selfRef.error_label = selfRef.scroll:addLabel({
        x = 2,
        y = 12,
        background = colors.lightGray,
        foreground = colors.white,
        width=var_width,
        text = "Error: "
    })
    selfRef.setpoint_num_label = selfRef.scroll:addLabel({
        x = 2 + var_width,
        y = 8,
        background = colors.lightGray,
        foreground = colors.white,
        width = 5,
        text = "" .. sigfig(self.setpoint, 5)
    })
    selfRef.output_num_label = selfRef.scroll:addLabel({
        x = 2 + var_width,
        y = 10,
        background = colors.lightGray,
        foreground = colors.white,
        width = 5,
        text = "" .. sigfig(self.output, 5)
    })
    selfRef.error_num_label = selfRef.scroll:addLabel({
        x = 2 + var_width,
        y = 12,
        background = colors.lightGray,
        foreground = colors.white,
        width = 5,
        text = "" .. sigfig(self.last_error, 5)
    })
end

return PID