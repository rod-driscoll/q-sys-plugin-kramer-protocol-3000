local CurrentPage = PageNames[props["page_index"].Value]
	
local colors = {  
  Background  = {232,232,232},
  Transparent = {255,255,255,0},
  Text        = {24,24,24},
  Header      = {0,0,0},
  Button      = {48,32,40},
  Red         = {217,32,32},
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
  if props["Connection Type"].Value=="Ethernet" then 
  table.insert(graphics,{Type="Text",Text="IP Address",Position={15,35},Size={100,16},FontSize=14,HTextAlign="Right"})
  layout["IPAddress"] = {PrettyName="Settings~IP Address",Style="Text",Color=colors.White,Position={120,35},Size={99,16},FontSize=12}
  table.insert(graphics,{Type="Text",Text="Port",Position={15,60},Size={100,16},FontSize=14,HTextAlign="Right"})
  layout["TcpPort"] = {PrettyName="Settings~Port",Style="Text",Position={120,60},Size={99,16},FontSize=12}
  table.insert(graphics,{Type="Text",Text="(5000 default)",Position={221,60},Size={100,18},FontSize=10,HTextAlign="Left"})
  table.insert(graphics,{Type="Text",Text="Reboot",Position={315,35},Size={70,14},FontSize=12,HTextAlign="Center",Color=colors.Text})
  layout["Reboot"] = {PrettyName="Power~Reboot", Style="Button", Color=colors.Button, FontColor=colors.Red, FontSize=14, CornerRadius=2, Position={325,48}, Size={50,20} }
  else
  table.insert(graphics,{Type="Text",Text="Reset Serial",Position={5,32},Size={110,16},FontSize=14,HTextAlign="Right"})
  layout["Reset"] = {PrettyName="Settings~Reset Serial", Style="Button", Color=colors.Button, FontColor=colors.Red, FontSize=14, CornerRadius=2, Position={120,30}, Size={50,20} }
  table.insert(graphics,{Type="Text",Text="Reboot",Position={15,57},Size={100,16},FontSize=14,HTextAlign="Right"})
  layout["Reboot"] = {PrettyName="Power~Reboot", Style="Button", Color=colors.Button, FontColor=colors.Red, FontSize=14, CornerRadius=2, Position={120,55}, Size={50,20} }
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

elseif(CurrentPage == 'Device') then 

  function copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
    return res
  end

  -- start with sizes of each object
  local base_obj_ 	= { Size={ 36, 36}				, Position={0,0} } -- a gain size, and the position of the xpt fader
  local btn_ 			= { Size={base_obj_.Size[1], 16}, Position={0,0}, Style="Button" }
  -- the word "Label"
  local output_label_ = { Size={108, btn_.Size[2]}	, Position={0,0}, Type="Text", Text="Label", FontSize=11, HTextAlign="Center" } 						
  -- Text entry field
  local output_name_ 	= { Size={output_label_.Size[1], base_obj_.Size[2]}, Position={0,0}, Type="Text", Style="Text", Color=colors.White, FontSize=9, HTextAlign="Center" }	
  local input_name_   = { Size={base_obj_.Size[1], 54}, Position={0,0}, Type="Text", Style="Text", Color=colors.White, FontSize=9, HTextAlign="Center" }
  -- number
  local output_num_ 	= { Size=base_obj_.Size			, Position={0,0}, Type="Text", FontSize=11, HTextAlign="Center" }	-- number text to be added later				
  local input_num_ 	= { Size=base_obj_.Size			, Position={0,0}, Type="Text", FontSize=11, HTextAlign="Center" }	-- number text to be added later				
  local gain_label_ 	= { Size=base_obj_.Size			, Position={0,0}, Type="Text", Text="Gain", FontSize=11, HTextAlign="Right" } -- the word 'gain'
  local fader_ 		= { Size={base_obj_.Size[1], 112},Position={0,0}, Style="Fader", ShowTextbox=true }
  local ramp_ 		= { Size={ 18, 12}				, Position={0,0}, Style="Button", Color=colors.Button, FontColor=colors.White, FontSize=9, CornerRadius=0, Margin=0 } --inc, dec
  local led_ 			= { Size={ 16, 16}				, Position={0,0}, Style="Led", Margin=3, StrokeWidth=1, UnlinkOffColor=false } --StrokeColor=colors.Gray }

  -- Most Positions are dynamic, when initialised positions are for the first item with a 1x1 matrix 
  local tbl_				= { Position={  8,  8}, Size=nil } -- offset of the entire table
  
  -- GroupBoxes, these sizes will be altered
  local grp_output		= { Position={tbl_.Position[1]    , tbl_.Position[2]+44}, Size={354, 60}, Type="GroupBox", Text="Output", StrokeWidth=1, CornerRadius=4, HTextAlign="Left" }
  local grp_input			= { Position={tbl_.Position[1]+220, tbl_.Position[2]   }, Size={ 44,328}, Type="GroupBox", Text="Input", StrokeWidth=1, CornerRadius=4, HTextAlign="Left" }
  local grp_output_gain	= { Position={tbl_.Position[1]+272, tbl_.Position[2]   }, Size={ 82,104}, Type="GroupBox", Text="Output", StrokeWidth=1, CornerRadius=4, HTextAlign="Left" }

  -- build an output row from left to right to use as reference positions
  output_label_.Position[2] = grp_output.Position[2]+4 -- the word "label"
  base_obj_.Position[2] = output_label_.Position[2] + output_label_.Size[2]
  output_num_.Position = { grp_output.Position[1]+4, base_obj_.Position[2] }
  output_label_.Position[1] = output_num_.Position[1] + output_num_.Size[1] + 8
  table.insert(graphics, output_label_)

  output_name_.Position = { output_label_.Position[1], base_obj_.Position[2] }
  local output_xpt_label_ = copy(gain_label_)
  output_xpt_label_.Text = "Route"
  output_xpt_label_.Position = { output_label_.Position[1]+output_label_.Size[1]+8, base_obj_.Position[2] + (base_obj_.Size[2] - btn_.Size[2]) / 2 }

  grp_input.Position[1] = output_xpt_label_.Position[1] + output_xpt_label_.Size[1] + 8
  grp_input.Size[1] = props['Input Count'].Value * (base_obj_.Size[1] + 4) + 4				-- multiplier
  base_obj_.Position[1] = grp_input.Position[1] + 4
  grp_output_gain.Position[1] = grp_input.Position[1] + grp_input.Size[1] + 8
  grp_output.Size[1] = grp_output_gain.Position[1] + grp_output_gain.Size[1] + 8 - grp_output.Position[1]

  local output_mute_label_ = copy(output_label_)
  output_mute_label_.Text = "Aud/Vid Mute"
  output_mute_label_.WordWrap = true
  output_mute_label_.Position = { grp_output_gain.Position[1], grp_output_gain.Position[2] + 10 }
  output_mute_label_.Size = { base_obj_.Size[1] + 8, base_obj_.Size[2] } 
  table.insert(graphics, output_mute_label_)

  local output_mute_ = copy(btn_)
  output_mute_.Position[1] = grp_output_gain.Position[1] + 4
  output_mute_.Color=colors.Red
  
  local output_disable_ = copy(output_mute_)
  output_disable_.Color=colors.Green
  output_disable_.Position[1] = output_mute_.Position[1]

  local output_gain_label_ = copy(output_mute_label_)
  output_gain_label_.Text = "Gain"
  output_gain_label_.Position[1] = output_mute_label_.Position[1] + output_mute_label_.Size[1]
  table.insert(graphics, output_gain_label_)

  local output_gain_ = copy(base_obj_)
  output_gain_.Style = "Knob"
  output_gain_.Position = { output_gain_label_.Position[1] + 4, base_obj_.Position[2] }

  -- input coordinates
  grp_output.Size[2] = output_label_.Size[2] + 4 + (props['Output Count'].Value * (base_obj_.Size[2] + 8))
  grp_output_gain.Size[1] = grp_output.Position[1] + grp_output.Size[1] - grp_output_gain.Position[1]
  grp_output_gain.Size[2] = grp_output.Position[2] + grp_output.Size[2] - grp_output_gain.Position[2]

  -- input labels
  local input_signal_label_ = copy(output_xpt_label_)
  input_signal_label_.Text = "Signal"
  input_signal_label_.Position[2] = grp_output.Position[2] + grp_output.Size[2] + 8
  input_signal_label_.Size[2] = led_.Size[2]
  table.insert(graphics, input_signal_label_)
  
  local input_gain_label_ = copy(output_xpt_label_)
  input_gain_label_.Text = "Gain"
  input_gain_label_.Position[2] = input_signal_label_.Position[2] + input_signal_label_.Size[2]
  input_gain_label_.Size[2] = fader_.Size[2]
  table.insert(graphics, input_gain_label_)
  
  local input_dec_ = copy(ramp_)
  input_dec_.Text = "-"
  input_dec_.String = "-=1"
  input_dec_.Position[2] = input_gain_label_.Position[2] + input_gain_label_.Size[2]
  local input_inc_ = copy(input_dec_)
  input_inc_.Text = "+"
  input_inc_.String = "+=1"
  input_inc_.Position[1] = input_dec_.Position[1] + input_dec_.Size[1]

  local input_label_ = copy(output_xpt_label_) -- the word 'Label'
  input_label_.Text = "Label"
  input_label_.Position[2] = input_inc_.Position[2] + input_inc_.Size[2] + 8
  input_label_.Size[2] = input_name_.Size[2]
  table.insert(graphics, input_label_)

  grp_input.Size[2] = input_label_.Position[2] + input_label_.Size[2] + 4
  
  table.insert(graphics, grp_output)
  table.insert(graphics, grp_input)
  table.insert(graphics, grp_output_gain)

  -- input items ( columns )
  --input_num_.Position = { base_obj_.Position[1], output_mute_label_.Position[2] }
  input_num_.Position = { base_obj_.Position[1], grp_input.Position[2] + 10 }

  --local input_mute_ = copy(btn_)
  local input_aud_signal_ = copy(led_)
  input_aud_signal_.Position = { base_obj_.Position[1], input_signal_label_.Position[2] }
  input_aud_signal_.Color=colors.Red
  --input_aud_signal_.OffColor=colors.DarkRed

  local input_vid_signal_ = copy(input_aud_signal_)
  input_vid_signal_.Color=colors.Green
  --input_vid_signal_.OffColor=colors.Green
  --input_vid_signal_.UnlinkOffColor=true
  --input_vid_signal_.Position[1] = input_vid_signal_.Position[1] + input_vid_signal_.Size[1]
  local input_gain_ = copy(fader_)
  input_gain_.Position = { base_obj_.Position[1], input_gain_label_.Position[2] }
  input_name_.Position = { base_obj_.Position[1], input_label_.Position[2] }
  
  -- draw outputs
  for o = 1, props['Output Count'].Value do -- For each output
    local pos_ = base_obj_.Position[2] + (o-1)*(base_obj_.Size[2] + 4)

    local num_ = copy(output_num_) -- number
    num_["Text"] = tostring(o)
    num_.Position[2] = pos_
    table.insert(graphics, num_)
    
    local xpt_label_ = copy(output_xpt_label_) -- the label "Route"
    xpt_label_.Position[2] = pos_
    table.insert(graphics, xpt_label_)

    local name_ = copy(output_name_)
    name_['PrettyName'] = "Outputs~Output ".. o .."~Output ".. o .." name"
    name_.Position[2] = pos_
    layout["output_" .. o .. "-name"] = name_
    
    local mute_ = copy(output_mute_)
    mute_['PrettyName'] = "Outputs~Output ".. o .."~Output ".. o .." mute"
    --mute_.Position[2] = pos_ + (base_obj_.Size[2] - mute_.Size[2]) / 2
    mute_.Position[2] = pos_
    layout["output_" .. o .. "-mute"] = mute_

    local disable_ = copy(output_disable_)
    disable_['PrettyName'] = "Outputs~Output ".. o .."~Output ".. o .." disable"
    disable_.Position[2] = pos_ + mute_.Size[2] + 2
    layout["output_" .. o .. "-disable"] = disable_
    
    local gain_ = copy(output_gain_)
    gain_['PrettyName'] = "Outputs~Output ".. o .."~Output ".. o .." level"
    gain_.Position[2] = pos_
    layout["output_" .. o .. "-level"] = gain_
  end

  -- draw inputs
  for i = 1, props['Input Count'].Value do -- For each input
    local pos_ = base_obj_.Position[1] + (i-1)*(base_obj_.Size[1] + 4)

    local num_ = copy(input_num_) -- number
    num_["Text"] = tostring(i)
    num_.Position[1] = pos_
    table.insert(graphics, num_)

    local name_ = copy(input_name_)
    name_['PrettyName'] = "Inputs~Input ".. i .."~Input ".. i .." name"
    name_.Position[1] = pos_
    layout["input_" .. i .. "-name"] = name_
    
    local gain_ = copy(input_gain_)
    gain_['PrettyName'] = "Inputs~Input ".. i .."~Input ".. i .." level"
    gain_.Position[1] = pos_
    layout["input_" .. i .. "-level"] = gain_

    local dec_ = copy(input_dec_)
    dec_['PrettyName'] = "Inputs~Input ".. i .."~Input ".. i .." down"
    dec_.Position[1] = pos_
    layout["input_" .. i .. "-level_down"] = dec_

    local inc_ = copy(input_inc_)
    inc_['PrettyName'] = "Inputs~Input ".. i .."~Input ".. i .." up"
    inc_.Position[1] = pos_ + inc_.Size[1]
    layout["input_" .. i .. "-level_up"] = inc_

    local aud_signal_ = copy(input_aud_signal_)
    aud_signal_['PrettyName'] = "Inputs~Input ".. i .."~Input ".. i .." audio signal present"
    aud_signal_.Position[1] = pos_
    layout["input_" .. i .. "-signal"] = aud_signal_

    local vid_signal_ = copy(input_vid_signal_)
    vid_signal_['PrettyName'] = "Inputs~Input ".. i .."~Input ".. i .." video signal present"
    vid_signal_.Position[1] = pos_ + aud_signal_.Size[1]
    layout["vid-input_" .. i .. "-signal"] = vid_signal_

  end

  -- draw crosspoints
  for o = 1, props['Output Count'].Value do -- For each output
    for i = 1, props['Input Count'].Value do -- For each input
      layout["vid-input_" .. i .. "-output_" .. o] = { 
        PrettyName = "Crosspoints~In" .. i .. " -> Out" .. o, 
        Style = "Button", 
        Legend = tostring(i), 
        Size = base_obj_.Size,
        Position = { base_obj_.Position[1] + (i-1)*(base_obj_.Size[1] + 4),  base_obj_.Position[2] + (o-1)*(base_obj_.Size[2] + 4) } }
    end
  end
end;
