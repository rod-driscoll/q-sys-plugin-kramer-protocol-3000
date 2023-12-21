
table.insert(ctrls, {
  Name         = "code",
  ControlType  = "Text",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Input"
})

-- Configuration Controls --
table.insert(ctrls, {
  Name         = "IPAddress",
  ControlType  = "Text",
  Count        = 1,
  DefaultValue = "Enter an IP Address",
  UserPin      = true,
  PinStyle     = "Both"
})
table.insert(ctrls, {
  Name         = "TcpPort",
  ControlType  = "Knob",
  ControlUnit  = "Integer",
  DefaultValue = 5000,
  Min          = 1,
  Max          = 65535,
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Both"
})
table.insert(ctrls, {
  Name         = "DeviceID",
  ControlType  = "Knob",
  ControlUnit  = "Integer",
  DefaultValue = 1,
  Min          = 0,
  Max          = 253,
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Both"
})
table.insert(ctrls, {
  Name         = "Username",
  ControlType  = "Text",
  DefaultValue = "admin",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Both"
})
table.insert(ctrls, {
  Name         = "Password",
  ControlType  = "Text",
  DefaultValue = "",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Both"
})

-- Status Controls --
table.insert(ctrls, {
  Name          = "Status",
  ControlType   = "Indicator",
  IndicatorType = Reflect and "StatusGP" or "Status",
  PinStyle      = "Output",
  UserPin       = true,
  Count         = 1
})
table.insert(ctrls, {
  Name         = "MachineNumber",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "ModelName",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "DeviceName",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "HostName",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "MACAddress",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1,
  DefaultValue = ""
})
table.insert(ctrls, {
  Name         = "DeviceFirmware",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})
table.insert(ctrls, {
  Name         = "SerialNumber",
  ControlType  = "Text",
  PinStyle     = "Output",
  UserPin      = true,
  Count        = 1
})

-- Switching Controls --

table.insert(ctrls, {
  Name         = "AFV",
  ControlType  = "Button",
  ButtonType   = "Toggle",
  PinStyle     = "Both",
  UserPin      = true,
  Count        = 1
})

for i = 0, props['Output Count'].Value do
  for s = 1, props['Input Count'].Value do
    table.insert(ctrls, {
      Name = "vid-input_" .. s .. "-output_" .. i,
      ControlType = "Button",
      ButtonType = "Toggle",
      PinStyle = "Both",
      UserPin = true
    })
    table.insert(ctrls, {
      Name = "aud-input_" .. s .. "-output_" .. i,
      ControlType = "Button",
      ButtonType = "Toggle",
      PinStyle = "Both",
      UserPin = true
    })
  end
end

-- input Controls --
--input levels are not specifically defined in protocol, however input level range is defined
for i = 0, props['Input Count'].Value do
  table.insert(ctrls,{
    Name         = "input_" .. i .. "-level",
    ControlType  = "Knob",
    ControlUnit  = "Integer",
    DefaultValue = 0,
    Min          = -83,
    Max          = 24,
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Both"
  })
  table.insert(ctrls, {
    Name         = "input_" .. i .. "-level_up",
    ControlType  = "Button",
    ButtonType   = "Momentary",
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Input",
    Icon         = "Plus"
  })
  table.insert(ctrls, {
    Name         = "input_" .. i .. "-level_down",
    ControlType  = "Button",
    ButtonType   = "Momentary",
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Input",
    Icon         = "Minus"
  })
  table.insert(ctrls, {
    Name         = "input_" .. i .. "-signal",
    ControlType  = "Indicator",
    IndicatorType= "Led",
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Output"
  })
  table.insert(ctrls, {
    Name         = "vid-input_" .. i .. "-signal",
    ControlType  = "Indicator",
    IndicatorType= "Led",
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Output"
  })
  table.insert(ctrls,{
    Name         = "input_" .. i .. "-name",
    ControlType  = "Text",
    DefaultValue = "Input " .. i,
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Both"
  })
  end

-- output Controls --
for i = 0, props['Output Count'].Value do
  table.insert(ctrls,{
    Name 		= "output_" .. i .. "-level",
    ControlType  = "Knob",
    ControlUnit  = "Integer",
    DefaultValue = 0,
    Min          = -83,
    Max          = 24,
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Both"
  })
  table.insert(ctrls, {
    Name         = "output_" .. i .. "-level_up",
    ControlType  = "Button",
    ButtonType   = "Trigger",
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Input",
    Icon         = "Plus"
  })
  table.insert(ctrls, {
    Name         = "output_" .. i .. "-level_Down",
    ControlType  = "Button",
    ButtonType   = "Trigger",
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Input",
    Icon         = "Minus"
  })
  table.insert(ctrls, {
    Name         = "output_" .. i .. "-mute",
    ControlType  = "Button",
    ButtonType   = "Toggle",
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Both"
  })
  table.insert(ctrls, {
    Name         = "output_" .. i .. "-disable",
    ControlType  = "Button",
    ButtonType   = "Toggle",
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Both"
  })
  table.insert(ctrls,{
    Name         = "output_" .. i .. "-name",
    ControlType  = "Text",
    DefaultValue = "Output " .. i,
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Both"
  })
  table.insert(ctrls, {
    Name         = "output_" .. i .. "-source",
    ControlType  = "Text",
    Style        = "ComboBox",
    Count        = 1,
    UserPin      = true,
    PinStyle     = "Both"
  })
end

table.insert(ctrls, {
  Name         = "SendString",
  ControlType  = "Text",
  Count        = 1,
  DefaultValue = "#VID 1>2",
  UserPin      = true,
  PinStyle     = "Input"
})
table.insert(ctrls, {
  Name         = "ReceivedString",
  ControlType  = "Text",
  Count        = 1,
  UserPin      = true,
  PinStyle     = "Output"
})
table.insert(ctrls, {
  Name         = "LockFrontPanel",
  ControlType  = "Button",
  PinStyle     = "Both",
  ButtonType   = "Toggle",
  UserPin      = true,
  Count        = 1
})