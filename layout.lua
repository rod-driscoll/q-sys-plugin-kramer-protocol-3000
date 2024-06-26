local CurrentPage = PageNames[props["page_index"].Value]
	
local colors = {  
  Background  = {232,232,232},
  Transparent = {255,255,255,0},
  Text        = {24,24,24},
  Header      = {0,0,0},
  Button      = {48,32,40},
  Red         = {217,32,32},
  Yellow      = {255,255,0},
  Orange      = {255,127,0},
  DarkRed     = {80,16,16},
  Green       = {32,217,32},
  OKGreen     = {48,144,48},
  Blue        = {32,32,233},
  Black       = {0,0,0},
  White       = {255,255,255},
  Gray        = {96,96,96}
}

local function label(graphic)
  for k,v in pairs({
    Type = 'Label',
    Color = { 0, 0, 0 },
    HTextAlign = 'Right',
    FontSize = 14
  }) do graphic[k] = graphic[k] or v; end;
  table.insert(graphics, graphic);
end;

local function textinput(layout)
  for k,v in pairs({
    Color = { 208, 208, 208 },
    StrokeColor = { 102, 102, 102 },
    StrokeWidth = 2,
    CornerRadius = 8,
    FontSize = 12,
    Margin = 10,
    TextBoxStyle = 'Normal'
  }) do layout[k] = layout[k] or v; end;
  return layout;
  end;

layout["code"]={PrettyName="code",Style="None"}  
    
if(CurrentPage == 'Setup') then
  -- User defines connection properties
  table.insert(graphics,{Type="GroupBox",Text="Connect",Fill=colors.Background,StrokeWidth=1,CornerRadius=4,HTextAlign="Left",Position={5,5},Size={400,120}})
  if props["Connection Type"].Value=="Serial" then 
    table.insert(graphics,{Type="Text",Text="Reset Serial",Position={5,32},Size={110,16},FontSize=14,HTextAlign="Right"})
    layout["Reset"] = {PrettyName="Settings~Reset Serial", Style="Button", Color=colors.Button, FontColor=colors.Red, FontSize=14, CornerRadius=2, Position={120,30}, Size={50,20} }
    --table.insert(graphics,{Type="Text",Text="Reboot",Position={15,57},Size={100,16},FontSize=14,HTextAlign="Right"})
    --layout["Reboot"] = {PrettyName="Power~Reboot", Style="Button", Color=colors.Button, FontColor=colors.Red, FontSize=14, CornerRadius=2, Position={120,55}, Size={50,20} }
  else
    table.insert(graphics,{Type="Text",Text="IP Address",Position={15,35},Size={100,16},FontSize=14,HTextAlign="Right"})
    layout["IPAddress"] = {PrettyName="Settings~IP Address",Style="Text",Color=colors.White,Position={120,35},Size={99,16},FontSize=12}
    table.insert(graphics,{Type="Text",Text="Port",Position={15,60},Size={100,16},FontSize=14,HTextAlign="Right"})
    layout["NetworkPort"] = {PrettyName="Settings~Port",Style="Text",Position={120,60},Size={99,16},FontSize=12}
    if props["Connection Type"].Value=="TCP" then 
      table.insert(graphics,{Type="Text",Text="(default TCP:5000)",Position={221,60},Size={100,18},FontSize=10,HTextAlign="Left"})
    elseif props["Connection Type"].Value=="UDP" then 
      table.insert(graphics,{Type="Text",Text="(default UDP:50000)",Position={221,60},Size={100,18},FontSize=10,HTextAlign="Left"})
    end
    --layout["Reboot"] = {PrettyName="Power~Reboot", Style="Button", Color=colors.Button, FontColor=colors.Red, FontSize=14, CornerRadius=2, Position={325,48}, Size={50,20} }
    --table.insert(graphics,{Type="Text",Text="Reboot",Position={315,35},Size={70,14},FontSize=12,HTextAlign="Center",Color=colors.Text})
  end
table.insert(graphics,{Type="Text",Text="Device ID",Position={15,85},Size={100,16},FontSize=14,HTextAlign="Right"})
  layout["DeviceID"] = {PrettyName="Settings~Device ID Number", Style="Text", FontColor=colors.Text, Position={120,85}, Size={99,16}, FontSize=12}

  -- Status fields updated upon connect show model/name/serial/sw rev
  table.insert(graphics,{Type="GroupBox",Text="Status",Fill=colors.Background,StrokeWidth=1,CornerRadius=4,HTextAlign="Left",Position={5,135},Size={400,220}})
  layout["Status"] = {PrettyName="Status~Connection Status", Position={40,165}, Size={330,32}, Padding=4 }
  table.insert(graphics,{Type="Text",Text="Device Name",Position={15,212},Size={100,16},FontSize=12,HTextAlign="Right"})
  layout["DeviceName"] = {PrettyName="Status~Device Name", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={120,211}, Size={255,16} }
  table.insert(graphics,{Type="Text",Text="Model Name",Position={15,235},Size={100,16},FontSize=12,HTextAlign="Right"})
  layout["ModelName"] = {PrettyName="Status~Model Name", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={120,234}, Size={255,16} }
  table.insert(graphics,{Type="Text",Text="Serial Number",Position={15,258},Size={100,16},FontSize=12,HTextAlign="Right"})
  layout["SerialNumber"] = {PrettyName="Status~Serial Number", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={120,257}, Size={255,16} }
  table.insert(graphics,{Type="Text",Text="Software Version",Position={15,281},Size={100,16},FontSize=12,HTextAlign="Right"})
  layout["DeviceFirmware"] = {PrettyName="Status~SW Version", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={120,280}, Size={255,16} }
  table.insert(graphics,{Type="Text",Text="MAC Address",Position={15,304},Size={100,16},FontSize=12,HTextAlign="Right"})
  layout["MACAddress"] = {PrettyName="Status~MAC Address", Style="Text", HTextAlign="Left", IsReadOnly=true, Color=colors.Transparent, StrokeWidth=0, FontSize=14, IsBold=true, FontColor=colors.Text, Position={120,303}, Size={255,16} }

  table.insert(graphics,{Type="Text",Text=GetPrettyName(),Position={15,200},Size={380,14},FontSize=10,HTextAlign="Right", Color=colors.Gray})

elseif(CurrentPage == 'Utilities') then 
  
  table.insert(graphics,{Type="Text",Text="Audio follow video",         Position={  8,  4},Size={110, 16},FontSize=12,HTextAlign="Right"})
  layout["AFV"] = {PrettyName="Audio follow video",Style="Button",      Position={122,  4},Size={ 36, 16},FontSize=12,Color=colors.Red,Margin=0 }
  table.insert(graphics,{Type="Text",Text="Send string",                Position={  8, 24},Size={110, 16},FontSize=12,HTextAlign="Right"})
  layout["SendString"] = {PrettyName="Send string",Style="Text",        Position={122, 24},Size={110, 16},FontSize=12,Color=colors.White}
  table.insert(graphics,{Type="Text",Text="Received string",            Position={  8, 42},Size={110, 16},FontSize=12,HTextAlign="Right"})
  layout["ReceivedString"] = {PrettyName="Received string",Style="Text",Position={122, 42},Size={110, 16},FontSize=12,Color=colors.Gray}
  table.insert(graphics,{Type="Text",Text="Lock front panel",               Position={  8, 60},Size={110, 16},FontSize=12,HTextAlign="Right"})
  layout["LockFrontPanel"] = {PrettyName="Lock front panel",Style="Button", Position={122, 60},Size={ 36, 16},FontSize=12,Color=colors.Red,Margin=0 }

elseif(CurrentPage == 'Matrix') then 

  --local helper = require("Helpers")
  helper = {}
  helper.Copy = function(tbl, seen)
    if type(tbl) ~= 'table' then return tbl end
    if seen and seen[tbl] then return seen[tbl] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(tbl))
    s[tbl] = res
    for k, v in pairs(tbl) do
        res[helper.Copy(k, s)] = helper.Copy(v, s)
    end
    if res==nil then print('Copy(): returning nil') end
    return res
  end  

  local large_matrix_size_ = { 12, 12 }
  -- create objects for each section so they can be modified easily
  -- add crosspoints (routes, labels, groupbox)
  local UI_crosspoints = {
    Position     = { 0, 8 },
    --Size        = { 0, 0 }, -- GroupBox contains Size of the whole object
    --buttons
    Padding     = { 4, 4 },
    GroupPadding= { 4, 4 },
    Button      = { Style = "Button", Size = { 36, 36}, Margin = 0 },
    AudioButton = { Style = "Button", Size = { 18, 12}, Margin = 0, FontSize=8, Color=colors.Red },
    NameText    = { Style = "Text", Type="Text", Color=colors.White, FontSize=10, HTextAlign="Center", WordWrap = true },
    NumButtons  = { props['Input Count'].Value, props['Output Count'].Value },
    Label       = { Style = "Label", Size = { 74, 14}, Type="Text", FontSize=10, HTextAlign="Center", WordWrap = true },
    Led         = { Style = "Led"  , Size = { 16, 16}, Margin=0, StrokeWidth=1, UnlinkOffColor=false },
    Outputs     = {}, -- to be filled in Init()
    AudioDigToDigOutputs= {}, -- to be filled in Init()
    AudioAnaToAnaOutputs= {}, -- to be filled in Init()
    AudioAnaToDigOutputs= {}, -- to be filled in Init()
    AudioDigToAnaOutputs= {}, -- to be filled in Init()
    --groupbox
    GroupBox    = { Type="GroupBox", Text="", StrokeWidth=1, CornerRadius=4, HTextAlign="Left" },
    
    Init = function (self)
      if props['Input Count'].Value > large_matrix_size_[1] or props['Output Count'].Value > large_matrix_size_[2] then 
        self.Padding     = { 1, 1 }
        self.Button.Size = { 18, 18 }
        self.AudioButton.Size = { 9, 6 }
        self.Led.Size = { 8, 8 }
        --self.Label.Size = { 37, 7 }
      end
      self.GroupBox.Size = {
        self.Padding[1] + self.NumButtons[1]*(self.Padding[1] + self.Button.Size[1]),
        self.Padding[2] + self.NumButtons[2]*(self.Padding[2] + self.Button.Size[2]) + self.Label.Size[2]+ self.Padding[2] }
      self.GroupBox.Position  = self.Position        
      --local newPos_ = {}
      local z=0
      for i=1, self.NumButtons[1] do          
        for o=1, self.NumButtons[2] do
          z=z+4
          local btn_ = helper.Copy(self.Button)
          btn_['PrettyName'] = "Crosspoints~Output "..o.."~In" .. i .. " -> Out" .. o
          btn_['Legend'] = tostring(i)
          btn_['Position']={
            self.GroupBox.Position[1] + self.Padding[1] + (i-1)*(self.Button.Size[1] + self.Padding[1]), -- moving accross
            self.GroupBox.Position[2] + self.Padding[2] + (o-1)*(self.Button.Size[2] + self.Padding[2]) + self.Label.Size[2]+ self.Padding[2] } -- moving down
          btn_['ZOrder'] = z
          btn_.Layout_ID = "vid-input_" ..i.. "-output_" .. o
          if self.Outputs[o]==nil then self.Outputs[o]={} end
          self.Outputs[o][i]=btn_

          local aud_d2d_ = helper.Copy(self.AudioButton)
          aud_d2d_['PrettyName'] = "Crosspoints~Output "..o.."~In" .. i .. " -> Out" .. o .. " audio"
          aud_d2d_['Legend'] = 'D'
          aud_d2d_['Color'] = colors.Red
          aud_d2d_['Position']={
            btn_.Position[1] + btn_.Size[1] - self.AudioButton.Size[1],
            btn_.Position[2] + btn_.Size[2] - self.AudioButton.Size[2] }
          aud_d2d_['ZOrder'] = z + 0x1000
          aud_d2d_.Layout_ID = "aud-input_" ..i.. "-output_" .. o
          if self.AudioDigToDigOutputs[o]==nil then self.AudioDigToDigOutputs[o]={} end
          self.AudioDigToDigOutputs[o][i]=aud_d2d_

          local aud_d2a_ = helper.Copy(self.AudioButton)
          aud_d2a_['PrettyName'] = "Crosspoints~Output "..o.."~In-digital" .. i .. " -> Out-analog" .. o .. " audio"
          aud_d2a_['Legend'] = 'D>A'
          aud_d2a_['Color'] = colors.Orange
          aud_d2a_['Position']={
            btn_.Position[1] + btn_.Size[1] - self.AudioButton.Size[1],
            btn_.Position[2] }
          aud_d2a_['ZOrder'] = z + 0x2000
          aud_d2a_.Layout_ID = "aud-input_" ..i.. "-ana-output_" .. o
          if self.AudioDigToAnaOutputs[o]==nil then self.AudioDigToAnaOutputs[o]={} end
          self.AudioDigToAnaOutputs[o][i]=aud_d2a_

          local aud_a2d_ = helper.Copy(self.AudioButton)
          aud_a2d_['PrettyName'] = "Crosspoints~Output "..o.."~In-analog" .. i .. " -> Out-digital" .. o .. " audio"
          aud_a2d_['Legend'] = 'A>D'
          aud_a2d_['Color'] = colors.Orange
          aud_a2d_['Position']={
            btn_.Position[1],
            btn_.Position[2] + btn_.Size[2] - self.AudioButton.Size[2] }
          aud_a2d_['ZOrder'] = z + 0x3000
          aud_a2d_.Layout_ID = "aud-ana-input_" ..i.. "-output_" .. o
          if self.AudioAnaToDigOutputs[o]==nil then self.AudioAnaToDigOutputs[o]={} end
          self.AudioAnaToDigOutputs[o][i]=aud_a2d_
          
          local aud_a2a_ = helper.Copy(self.AudioButton)
          aud_a2a_['PrettyName'] = "Crosspoints~Output "..o.."~In-analog" .. i .. " -> Out-analog" .. o .. " audio"
          aud_a2a_['Legend'] = 'A'
          aud_a2a_['Color'] = colors.Yellow
          aud_a2a_['Position']={
            btn_.Position[1],
            btn_.Position[2] }
          aud_a2a_['ZOrder'] = z + 0x4000
          aud_a2a_.Layout_ID = "aud-ana-input_" ..i.. "-ana-output_" .. o
          if self.AudioAnaToAnaOutputs[o]==nil then self.AudioAnaToAnaOutputs[o]={} end
          self.AudioAnaToAnaOutputs[o][i]=aud_a2a_
        end
      end
    end,

    Draw = function(self, layout)
      table.insert(graphics, self.GroupBox)
      for _,o in pairs(self.Outputs) do 
        for _,i in pairs(o) do layout[i.Layout_ID] = i end -- layout is the global layout
      end
      for _,o in pairs(self.AudioDigToDigOutputs) do 
        for _,i in pairs(o) do layout[i.Layout_ID] = i end -- layout is the global layout
      end
      for _,o in pairs(self.AudioDigToAnaOutputs) do 
        for _,i in pairs(o) do layout[i.Layout_ID] = i end -- layout is the global layout
      end
      for _,o in pairs(self.AudioAnaToDigOutputs) do 
        for _,i in pairs(o) do layout[i.Layout_ID] = i end -- layout is the global layout
      end
      for _,o in pairs(self.AudioAnaToAnaOutputs) do 
        for _,i in pairs(o) do layout[i.Layout_ID] = i end -- layout is the global layout
      end
    end,

    Move = function(self, distance)
      self.Position[1] = self.Position[1] + distance[1]
      self.Position[2] = self.Position[2] + distance[2]
      for _,o in pairs(self.Outputs) do 
        for _,i in pairs(o) do 
          i.Position[1] = i.Position[1] + distance[1]
          i.Position[2] = i.Position[2] + distance[2]
        end
      end
      for _,ao in pairs(self.AudioDigToDigOutputs) do 
        for _,ai in pairs(ao) do 
          ai.Position[1] = ai.Position[1] + distance[1]
          ai.Position[2] = ai.Position[2] + distance[2]
        end
      end
      for _,ao in pairs(self.AudioDigToAnaOutputs) do 
        for _,ai in pairs(ao) do 
          ai.Position[1] = ai.Position[1] + distance[1]
          ai.Position[2] = ai.Position[2] + distance[2]
        end
      end
      for _,ao in pairs(self.AudioAnaToDigOutputs) do 
        for _,ai in pairs(ao) do 
          ai.Position[1] = ai.Position[1] + distance[1]
          ai.Position[2] = ai.Position[2] + distance[2]
        end
      end
      for _,ao in pairs(self.AudioAnaToAnaOutputs) do 
        for _,ai in pairs(ao) do 
          ai.Position[1] = ai.Position[1] + distance[1]
          ai.Position[2] = ai.Position[2] + distance[2]
        end
      end
    end
  }

  -- add outputs (names, locks)
  local UI_outputObjects = {
    --Position    = helper.Copy(UI_crosspoints.GroupBox.Position),
    Position    = helper.Copy(UI_crosspoints.Position),
    --buttons
    Padding     = helper.Copy(UI_crosspoints.Padding),
    NameText    = helper.Copy(UI_crosspoints.NameText), --Size = { 36, 54}      
    NumButtons  = props['Output Count'].Value,
    Buttons     = {}, -- to be filled in Init()
    Labels      = {}, -- to be filled in Init()
    --groupbox
    GroupBox    = helper.Copy(UI_crosspoints.GroupBox),

    Init = function(self)
      self.NameText.Size = { 76, UI_crosspoints.Button.Size[2] }
      self.LockButtons = {}
      -- GroupBox
      self.GroupBox.Size = {
        self.Padding[1], -- horiz, to be increased as buttons added
        UI_crosspoints.GroupBox.Size[2] } -- vert same as crosspoint GroupBox
      self.GroupBox.Position = self.Position
      self.GroupBox.Text="Outputs"

      local newPos_ = {}

      for o=1, self.NumButtons do
        newPos_ = {
          self.GroupBox.Position[1] + self.Padding[1], -- horiz always the same [output:0][input:0][horiz]
          UI_crosspoints.Outputs[o][1].Position[2] } -- vert moves down
        
          -- left column of labels (numbers only)
        local num_ = helper.Copy(UI_crosspoints.Label)
        num_.Size = { 18, UI_crosspoints.Button.Size[2] }
        num_["Text"] = tostring(o)
        num_['Position'] = helper.Copy(newPos_)
        table.insert(self.Labels, num_)
        newPos_[1] = newPos_[1] + num_.Size[1] + self.Padding[1]
        if o==1 then self.GroupBox.Size[1] = self.GroupBox.Size[1] + num_.Size[1] + self.Padding[1] end

        -- Names
        local name_ = helper.Copy(self.NameText)
        name_['PrettyName'] = "Outputs~".. o .."~name"
        name_['Position'] = helper.Copy(newPos_)
        name_.Layout_ID = "output_" .. o .. "-name"
        table.insert(self.Buttons, name_)
        newPos_[1] = newPos_[1] + name_.Size[1] + self.Padding[1]
        if o==1 then self.GroupBox.Size[1] = self.GroupBox.Size[1] + name_.Size[1] + self.Padding[1] end
      end
      -- set new position of UI_Crosspoints
      UI_crosspoints:Move({ newPos_[1] - UI_crosspoints.Outputs[1][1].Position[1] + self.Padding[1], 0})
      self.GroupBox.Size[1] = self.GroupBox.Size[1] + UI_crosspoints.GroupBox.Size[1]
    end,

    Draw = function(self, layout)
      table.insert(graphics, self.GroupBox)
      for _,l in ipairs(self.Labels ) do table.insert(graphics, l) end
      for _,b in ipairs(self.Buttons) do layout[b.Layout_ID] = b  end-- layout is the global layout
    end,

    Move = function(self, distance)
      self.Position[1] = self.Position[1] + distance[1]
      self.Position[2] = self.Position[2] + distance[2]
      for _,l in ipairs(self.Labels) do 
        l.Position[1] = l.Position[1] + distance[1]
        l.Position[2] = l.Position[2] + distance[2]
      end
      for _,b in pairs(self.Buttons) do 
        b.Position[1] = b.Position[1] + distance[1]
        b.Position[2] = b.Position[2] + distance[2]
      end
    end
  }

 -- add inputs (names)
  local UI_inputObjects = {
    Position    = {},
    --buttons
    Padding     = helper.Copy(UI_crosspoints.Padding),
    Button      = helper.Copy(UI_crosspoints.Button),
    Led         = helper.Copy(UI_crosspoints.Led),
    Label       = helper.Copy(UI_crosspoints.Label),
    NameText    = helper.Copy(UI_crosspoints.NameText),
    NumButtons  = props['Input Count'].Value,
    Nudge       = { Style = "Button", Size = {18,12}, Margin=0, Color=colors.Button, FontColor=colors.White, FontSize=9, CornerRadius=0 },
    Buttons     = {}, -- to be filled in Init()
    Labels      = {}, -- to be filled in Init()
    --groupbox
    GroupBox    = helper.Copy(UI_crosspoints.GroupBox),

    Init = function(self)
      self.NameText.Size = { UI_crosspoints.Button.Size[1], 54 }
      self.Label.HTextAlign = "Right"
      self.Position = helper.Copy(UI_crosspoints.GroupBox.Position)
      -- GroupBox   
      self.GroupBox.Size = {
        UI_crosspoints.GroupBox.Size[1], -- horiz, same as crosspoints
        UI_crosspoints.Label.Size[2] + self.Padding[2] + UI_crosspoints.Label.Size[2] + self.Padding[2] + UI_crosspoints.GroupBox.Size[2] + self.Padding[2] } -- vert, increase as objects added   
      self.GroupBox.Position = self.Position
      self.GroupBox.Text="Inputs"

      if props['Input Count'].Value > large_matrix_size_[1] or props['Output Count'].Value > large_matrix_size_[2] then 
        self.Padding     = {  1, 1 }
        self.Button.Size = { 18, 18 }
        self.Led.Size    = { 8, 8 }
      end
      local newPos_ = {}

      for i=1, self.NumButtons do
        newPos_ = {
          UI_crosspoints.Outputs[1][i].Position[1],
          self.Position[2] + self.Label.Size[2] + self.Padding[2] } -- vert always the same
        
        -- top row of labels (numbers only) above crosspoints
        local lbl_ = helper.Copy(UI_crosspoints.Label)
        lbl_.Size[1] = self.Button.Size[1]
        lbl_["Text"] = tostring(i)            
        lbl_['Position'] = helper.Copy(newPos_)
        table.insert(self.Labels, lbl_)
        newPos_[2] = lbl_.Position[2] + lbl_.Size[2] + self.Padding[2] + UI_crosspoints.GroupBox.Size[2] + self.Padding[2]

        -- below crosspoints
        -- Audio signal present
        local asignal_ = helper.Copy(self.Led)
        asignal_.Color=colors.Red
        asignal_['PrettyName'] = "Inputs~".. i .."~audio signal present"
        asignal_['Position'] = helper.Copy(newPos_)
        asignal_.Layout_ID = "input_" .. i .. "-signal"
        table.insert(self.Buttons, asignal_)
        --newPos_[2] = asignal_.Position[2] + asignal_.Size[2] + self.Padding[2]
        --if i==1 then self.GroupBox.Size[2] = self.GroupBox.Size[2] + asignal_.Size[2] + self.Padding[2] end

        -- Video signal present
        local vsignal_ = helper.Copy(self.Led)
        vsignal_.Color=colors.Green
        vsignal_['PrettyName'] = "Inputs~".. i .."~video signal present"
        vsignal_['Position'] = { 
          asignal_.Position[1] + asignal_.Size[1] + self.Padding[1],
          asignal_.Position[2] }
        if props['Input Count'].Value > large_matrix_size_[1] or props['Output Count'].Value > large_matrix_size_[2] then 
          vsignal_.Position[1] = asignal_.Position[1] + asignal_.Size[1]
        end
        vsignal_.Layout_ID = "vid-input_" .. i .. "-signal"
        table.insert(self.Buttons, vsignal_)
        if i==1 then 
          -- label to the left of the groupbox
          local lbl_signal_ = helper.Copy(self.Label)
          lbl_signal_["Text"] = "A/V Signal"            
          lbl_signal_['Position']={
            self.GroupBox.Position[1] - self.Padding[1] - lbl_signal_.Size[1], 
            newPos_[2] }
          lbl_signal_.Size[2] = vsignal_.Size[2]
          table.insert(self.Labels, lbl_signal_)
          self.GroupBox.Size[2] = self.GroupBox.Size[2] + vsignal_.Size[2] + self.Padding[2] 
        end
        newPos_[2] = vsignal_.Position[2] + vsignal_.Size[2] + self.Padding[2]

        if props['Model'].Value=='Other' then
            -- Gains
          local level_ = helper.Copy(self.Button)
          level_['PrettyName'] = "Inputs~".. i .."~level"
          level_['Position'] = helper.Copy(newPos_)
          level_['Style'] = "Fader"
          level_.ShowTextbox = true
          if props['Input Count'].Value > large_matrix_size_[1] or props['Output Count'].Value > large_matrix_size_[2] then 
            level_.Size[2] = 75
          else
            level_.Size[2] = 112
          end
          level_.Layout_ID = "input_" .. i .. "-level"
          table.insert(self.Buttons, level_)
          if i==1 then
            -- label to the left of the groupbox
            local lbl_level_ = helper.Copy(self.Label)
            lbl_level_["Text"] = "Gain"            
            lbl_level_['Position']={
              self.GroupBox.Position[1] - self.Padding[1] - lbl_level_.Size[1], 
              newPos_[2] }
              lbl_level_.Size[2] = level_.Size[2]
            table.insert(self.Labels, lbl_level_)
            self.GroupBox.Size[2] = self.GroupBox.Size[2] + level_.Size[2] + self.Padding[2]
          end
          newPos_[2] = level_.Position[2] + level_.Size[2]-- + self.Padding[2]

          --Gain dec
          local dec_ = helper.Copy(self.Nudge)
          dec_['PrettyName'] = "Inputs~".. i .."~down"
          dec_['Position'] = helper.Copy(newPos_)
          if props['Input Count'].Value > large_matrix_size_[1] or props['Output Count'].Value > large_matrix_size_[2] then 
            dec_.Position[2] = dec_.Position[2] + dec_.Size[2] 
          end
          dec_.Text = "-"
          dec_.String = "-=1"
          dec_.Layout_ID = "input_" .. i .. "-level_down"
          table.insert(self.Buttons, dec_)
          --newPos_[2] = dec_.Position[2] + dec_.Size[2] + self.Padding[2]
          --if i==1 then self.GroupBox.Size[2] = self.GroupBox.Size[2] + dec_.Size[2] + self.Padding[2] end

          --Gain inc
          local inc_ = helper.Copy(dec_)
          inc_['PrettyName'] = "Inputs~".. i .."~up"
          if props['Input Count'].Value > large_matrix_size_[1] or props['Output Count'].Value > large_matrix_size_[2] then 
            inc_.Position[2] = newPos_[2] 
          else
            inc_.Position[1] = dec_.Position[1] + dec_.Size[1]
          end
          inc_.Text = "+"
          inc_.String = "+=1"
          inc_.Layout_ID = "input_" .. i .. "-level_up"
          table.insert(self.Buttons, inc_)
          if i==1 then self.GroupBox.Size[2] = self.GroupBox.Size[2] + inc_.Size[2] + self.Padding[2] end
          if props['Input Count'].Value > large_matrix_size_[1] or props['Output Count'].Value > large_matrix_size_[2] then 
            newPos_[2] = dec_.Position[2] + dec_.Size[2] + self.Padding[2]
          else
            newPos_[2] = inc_.Position[2] + inc_.Size[2] + self.Padding[2]
          end
        end

        -- Names
        local name_ = helper.Copy(self.NameText)
        name_['PrettyName'] = "Inputs~".. i .."~name"
        name_['Position'] = helper.Copy(newPos_)
        name_.Layout_ID = "input_" .. i .. "-name"
        table.insert(self.Buttons, name_)
        if i==1 then
          -- label to the left of the groupbox
          local lbl_name_ = helper.Copy(self.Label)
          lbl_name_["Text"] = "Label"            
          lbl_name_['Position']={
            self.GroupBox.Position[1] - self.Padding[1] - lbl_name_.Size[1], 
            newPos_[2] }
          lbl_name_.Size[2] = name_.Size[2]
          table.insert(self.Labels, lbl_name_)
          self.GroupBox.Size[2] = self.GroupBox.Size[2] + name_.Size[2] + self.Padding[2]
        end
        newPos_[2] = name_.Position[2] + name_.Size[2] + self.Padding[2]
      end
      
      -- move other objects down
      UI_crosspoints:Move  ({0, UI_crosspoints.Label.Size[2] + self.Padding[2] + UI_crosspoints.Label.Size[2] + self.Padding[2] })
      UI_outputObjects:Move({0, UI_crosspoints.Label.Size[2] + self.Padding[2] + UI_crosspoints.Label.Size[2] + self.Padding[2] })
    end,

    Draw = function(self, layout)
      table.insert(graphics, self.GroupBox)
      for _,l in ipairs(self.Labels ) do table.insert(graphics, l) end
      for _,b in ipairs(self.Buttons) do  layout[b.Layout_ID] = b end -- layout is the global layout
    end,

    Move = function(self, distance)
      self.Position[1] = self.Position[1] + distance[1]
      self.Position[2] = self.Position[2] + distance[2]
      self.GroupBox.Position[1] = self.GroupBox.Position[1] + distance[1]
      self.GroupBox.Position[2] = self.GroupBox.Position[2] + distance[2]
      for _,l in ipairs(self.Labels) do 
        l.Position[1] = l.Position[1] + distance[1]
        l.Position[2] = l.Position[2] + distance[2]
      end
      for _,b in pairs(self.Buttons) do 
        b.Position[1] = b.Position[1] + distance[1]
        b.Position[2] = b.Position[2] + distance[2]
      end
    end
  }

  -- add post fade objects (source ComboBoxes)
  local UI_postFadeObjects = {
    Position    = helper.Copy(UI_crosspoints.Position),
    --buttons
    Button      = helper.Copy(UI_crosspoints.Button),
    Label       = helper.Copy(UI_crosspoints.Label),
    Padding     = helper.Copy(UI_crosspoints.Padding),
    Selector    = { Style = "ComboBox", Type="Text", Size={76, UI_crosspoints.Button.Size[2]}, Color=colors.White, FontSize=10, HTextAlign="Center", WordWrap = true },
    NumButtons  = props['Output Count'].Value,
    Buttons     = {}, -- to be filled in Init()
    Labels      = {}, -- to be filled in Init()
    --groupbox
    GroupBox    = helper.Copy(UI_crosspoints.GroupBox),

    Init = function(self)
      -- GroupBox
      self.GroupBox.Size = {
          self.Padding[1], -- horiz, to be increased as buttons added
          UI_crosspoints.Label.Size[2] + self.Padding[2] + UI_crosspoints.Label.Size[2] + self.Padding[2] + UI_crosspoints.GroupBox.Size[2] } -- vert, increase as objects added   
      self.GroupBox.Position = {
        UI_crosspoints.GroupBox.Position[1] + UI_crosspoints.GroupBox.Size[1] + self.Padding[1],
        UI_inputObjects.GroupBox.Position[2] }
      self.GroupBox.Text="Output"
      --self.Label.HTextAlign="Right"
      if props['Input Count'].Value > large_matrix_size_[1] or props['Output Count'].Value > large_matrix_size_[2] then 
        self.Padding = { 1, 1 }
        self.Button.Size = { 18, 18 }
        self.Selector.Size[2] = 18
        self.Label.FontSize = 6
      end
      local newPos_ = {}

      for o=1, self.NumButtons do
        local newPos_ = {
          self.GroupBox.Position[1] + self.Padding[1], 
          UI_crosspoints.Outputs[o][1].Position[2] }
        
        -- A/V Mutes
        local amute_ = helper.Copy(self.Button)
        amute_['Color'] = colors.Red
        if props['Input Count'].Value > large_matrix_size_[1] or props['Output Count'].Value > large_matrix_size_[2] then 
          amute_.Size[2] = 8
        else
          amute_.Size[2] = 16
        end
        amute_['PrettyName'] = "Outputs~".. o .."~mute"
        amute_['Position'] = helper.Copy(newPos_) 
        amute_.Layout_ID = "output_" .. o .. "-mute"
        table.insert(self.Buttons, amute_)

        local vmute_ = helper.Copy(amute_)
        vmute_.Color = colors.Green
        vmute_['PrettyName'] = "Outputs~".. o .."~disable"
        vmute_.Position[2] = amute_.Position[2] + amute_.Size[2] + self.Padding[2]
        vmute_.Layout_ID = "output_" .. o .. "-disable"
        table.insert(self.Buttons, vmute_)

        -- top row mutes label (text only) above crosspoints GroupBox
        if o==1 then
          local lbl_mute_ = helper.Copy(self.Label)
          lbl_mute_.Size = {
            self.Button.Size[1] + 2*self.Padding[1], -- need it wider so use up all the padding
            22 } 
          lbl_mute_["Text"] = "Aud/Vid Mute"            
          lbl_mute_['Position']={
            self.GroupBox.Position[1], -- horiz moves accross
            self.Position[2] + UI_crosspoints.Label.Size[2] } -- vert always the same
          table.insert(self.Labels, lbl_mute_)

          self.GroupBox.Size[1] = self.GroupBox.Size[1] + amute_.Size[1] + self.Padding[1]
        end
        newPos_[1] = newPos_[1] + amute_.Size[1] + self.Padding[1]
               
        -- Gain knob
        local gain_ = helper.Copy(self.Button)
        gain_['PrettyName'] = "Outputs~".. o .."~level"
        gain_['Style'] = "Knob"
        gain_['Position'] = helper.Copy(newPos_)
        gain_.Layout_ID = "output_" .. o .. "-level"
        table.insert(self.Buttons, gain_)

        -- top row gain knob label (text only) above crosspoints GroupBox
        if o==1 then
          local lbl_gain_ = helper.Copy(self.Label)
          lbl_gain_.Size[1] = self.Button.Size[1]
          lbl_gain_["Text"] = "Gain"            
          lbl_gain_['Position']={
            newPos_[1], -- horiz moves accross
            self.Position[2] + UI_crosspoints.Label.Size[2] + self.Padding[2] } -- vert always the same
          table.insert(self.Labels, lbl_gain_)
          self.GroupBox.Size[1] = self.GroupBox.Size[1] + gain_.Size[1] + self.Padding[1]
        end
        newPos_[1] = newPos_[1] + gain_.Size[1] + self.Padding[1]
      
        -- source select ComboBox
        local selector_ = helper.Copy(self.Selector)
        selector_['PrettyName'] = "Outputs~".. o .."~source"
        selector_['Position']= helper.Copy(newPos_)
        selector_.Layout_ID = "output_" .. o .. "-source"
        table.insert(self.Buttons, selector_)

        -- top row selector label (text only) above crosspoints GroupBox
        if o==1 then
          local lbl_selector_ = helper.Copy(self.Label)
          lbl_selector_.Size[1] = selector_.Size[1]
          lbl_selector_["Text"] = "Input select"            
          lbl_selector_['Position']={
            newPos_[1], -- horiz moves accross
            self.Position[2] + UI_crosspoints.Label.Size[2] + self.Padding[2] } -- vert always the same
          table.insert(self.Labels, lbl_selector_)
          self.GroupBox.Size[1] = self.GroupBox.Size[1] + selector_.Size[1] + self.Padding[1]
        end
        newPos_[1] = newPos_[1] + selector_.Size[1] + self.Padding[1]

      end

      UI_outputObjects.GroupBox.Size[1] = UI_outputObjects.GroupBox.Size[1] + self.Padding[1] + self.GroupBox.Size[1]
    end,

    Draw = function(self, layout)
      table.insert(graphics, self.GroupBox)
      for _,l in ipairs(self.Labels ) do table.insert(graphics, l) end
      for _,b in ipairs(self.Buttons) do layout[b.Layout_ID] = b  end-- layout is the global layout
    end,

    Move = function(self, distance)
      self.Position[1] = self.Position[1] + distance[1]
      self.Position[2] = self.Position[2] + distance[2]
      for _,l in ipairs(self.Labels) do 
        l.Position[1] = l.Position[1] + distance[1]
        l.Position[2] = l.Position[2] + distance[2]
      end
      for _,b in pairs(self.Buttons) do 
        b.Position[1] = b.Position[1] + distance[1]
        b.Position[2] = b.Position[2] + distance[2]
      end
    end
  }

  UI_crosspoints:Init() -- initialize the crosspoints so other components can reference it's positions
  UI_outputObjects:Init() -- this also moves crosspoints to the right
  UI_inputObjects:Init() -- this also moves crosspoints down
  UI_postFadeObjects:Init() -- this also expands output GroupBox to the right
  
  UI_crosspoints:Draw(layout)
  UI_outputObjects:Draw(layout)
  UI_inputObjects:Draw(layout)
  UI_postFadeObjects:Draw(layout)

end