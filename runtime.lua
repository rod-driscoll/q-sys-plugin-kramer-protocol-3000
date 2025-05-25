--local helper = require('helpers')

-- Control aliases
Status = Controls.Status

--local SimulateFeedback = System.IsEmulating
local SimulateFeedback = false
-- Variables and flags
DebugTx=false
DebugRx=false
DebugFunction=false
DebugPrint=Properties["Debug Print"].Value	

-- Timers, tables, and constants
StatusState = { OK = 0, COMPROMISED = 1, FAULT = 2, NOTPRESENT = 3, MISSING = 4, INITIALIZING = 5 }
Heartbeat = Timer.New()
VolumeDebounce = Timer.New()
PollRate = Properties["Poll Interval"].Value
Timeout = PollRate + 10
BufferLength = 1024
ConnectionType = Properties["Connection Type"].Value
DataBuffer = ""
CommandQueue = {}
CommandProcessing = false
CurrentCommand = {}
--Internal command timeout
CommandTimeout = 5
if System.IsEmulating then CommandTimeout = 120 end
CommunicationTimer = Timer.New()
TimeoutCount = 0

local Layers = { Video = 1, Audio = 2, Data  = 3, IR = 4, USB = 5 }
local AudioLayer = { Analog = 0, Digital = 1 }
local QueryRouteType = Layers.Video
local UpdatingVideoChoices = false

local NoSourceName = "No source"

--Hide controls that are just for pins
--Controls["ModelNumber"].IsInvisible=true
--Controls["PanelType"].IsInvisible=true

local Request = {
	Status			={Command="",			Data=""},
	AudioEmbedding	={Command="AUD-EMB",	Data=""},
	AudioFollowVideo	={Command="AFV",	Data=""},
	AudioLevel		={Command="AUD-LVL",	Data=""},
	AudioRoute	={Command="AUD",Data=""}, -- Legacy
	AudioLevelRange	={Command="AUD-LVL-RANGE",Data=""},
	AudioSignalPresent={Command="AUD-SIGNAL",Data=""},
	AutoSwitchMode	={Command="AV-SW-MODE",	Data=""},
	AutoSwitchTimeout={Command="AV-SW-TIMEOUT",Data=""},
	AvRoute   ={Command="AV",Data=""},
	DeviceInfo		={Command="BEACON-INFO",Data=""},
	BuildDate		={Command="BUILD-DATE",	Data=""},
	CopyEDIDSet		={Command="CPEDID",		Data=""},
	HPD				={Command="DISPLAY",	Data=""},
	DipSwitch		={Command="DPSW-STATUS",Data=""},
	EthernetPort	={Command="ETH-PORT",	Data=""},
	ExternalAudio	={Command="EXT-AUD",	Data=""},
	Error			={Command="ERR",		Data=""},
	FactoryReset	={Command="FACTORY",	Data=""},
	FPGAVersion		={Command="FPGA-VER",	Data=""},
	HDCPMode		={Command="HDCP-MOD",	Data=""},
	HDCPStatus		={Command="HDCP-STAT",	Data=""},
	Help			={Command="HELP",		Data=""},
	Label		={Command="LABEL",	Data=""},
	LockEDID		={Command="LOCK-EDID",	Data=""},
	LockFrontPanel		={Command="LOCK-FP",	Data=""},
	Login			={Command="LOGIN",		Data=""},
	Logout			={Command="LOGOUT",		Data=""},
	Model			={Command="MODEL",		Data=""},
	Mute			={Command="MUTE",		Data=""},
	HostName		={Command="NAME",		Data=""},
	ResetName		={Command="NAME-RST",	Data=""},
	NetworkConfig	={Command="NET-CONFIG",	Data=""},
	DHCP			={Command="NET-DHCP",	Data=""},
	Gateway			={Command="NET-GATE",	Data=""},
	IPAddress		={Command="NET-IP",		Data=""},
	MACAddress		={Command="NET-MAC",	Data=""},
	NetMask			={Command="NET-MASK",	Data=""},
	Password		={Command="PASS",		Data=""},
	ProtocolVersion	={Command="PROT-VER",	Data=""},
	PresetList	={Command="PRST-LST",	Data=""},
	PresetRecall	={Command="PRST-RCL",	Data=""},
	PresetStore	={Command="PRST-STO",	Data=""},
	Reset			={Command="RESET",		Data=""},
	Route			={Command="ROUTE",		Data=""}, -- Legacy
	Security		={Command="SECUR",		Data=""},
	SignalPresent	={Command="SIGNAL",		Data=""},
	SerialNumber	={Command="SN",			Data=""},
	Time			={Command="TIME",		Data=""},
	TestPattern	={Command="VID-PATTERN",		Data=""},
	TimeZone		={Command="TIME-LOC",	Data=""},
	TimeServer		={Command="TIME-SRV",	Data=""},
	DeviceFirmware	={Command="VERSION",	Data=""},
	VGAPhase		={Command="VGA-PHASE",	Data=""},
	VideoMute		={Command="VMUTE",		Data=""},
	VideoRoute   ={Command="VID",Data=""}, -- Legacy
	Volume		={Command="VOLUME",		Data=""},
}

-- Helper functions
-- A function to determine common print statement scenarios for troubleshooting
function SetupDebugPrint()
	if DebugPrint=="Tx/Rx" then
		DebugTx,DebugRx=true,true
	elseif DebugPrint=="Tx" then
		DebugTx=true
	elseif DebugPrint=="Rx" then
		DebugRx=true
	elseif DebugPrint=="Function Calls" then
		DebugFunction=true
	elseif DebugPrint=="All" then
		DebugTx,DebugRx,DebugFunction=true,true,true
	end
end

function find_value(target, value)
	--print("find_value("..value..") type: ", type(target))
	if(type(target) == 'table') then
		for i,v in pairs(target) do
			if v == value then return(i) end
		end  
	elseif(type(target) == 'array') then
		for i,v in ipairs(target) do
			if v == value then return(i) end
		end
	elseif(type(target) == 'string') then
		return(target:find(value))
	end
	return false
end

-- A function to clear controls/flags/variables and clears tables
function ClearVariables()
	if DebugFunction then print("ClearVariables() Called") end
	Controls["SerialNumber"].String = ""
	Controls["DeviceFirmware"].String = ""
	Controls["ModelName"].String = ""
	Controls["DeviceName"].String = ""
	Controls["MACAddress"].String = ""
	DataBuffer = ""
	CommandQueue = {}
end

--Reset any of the "Unavailable" data;  Will cause a momentary colision that will resolve itself the customer names the device "Unavailable"
function ClearUnavailableData()
	if DebugFunction then print("ClearUnavailableData() Called") end
	-- If data was unavailable reset it; the next poll loop will test for it again
	for i,ctrl in ipairs({ "SerialNumber", "DeviceFirmware", "ModelNumber", "ModelName", "DeviceName", "MACAddress" }) do
		if(Controls[ctrl].String == "Unavailable")then
			Controls[ctrl].String = ""
		end
	end
end

-- Update the Status control
function ReportStatus(state,msg)
	if DebugFunction then print("ReportStatus() Called: "..state.." - "..msg) end
	local msg=msg or ""
	Status.Value=StatusState[state]
	Status.String=msg
end


function Split(s, delimiter)
	if DebugFunction then print("Split() Called") end
	local result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match);
	end
	return result;
end

--Parse a string from byte array
function ParseString(data)
	if DebugFunction then print("ParseString() Called") end
	local name = ""
	for i,byte in ipairs(data) do
		name = name .. string.char(byte)
	end
	return name
end

function GetPrintableHexString(str)
	local result_ = ""
	for i=1, #str do
		local c = str:sub(i,i)
		if c:byte() > 0x1F and c:byte() < 0x7F then
			result_ = result_..c
		else
			result_ = result_..string.format("\\x%02X", c:byte())
		end
	end
	return result_  
end

--A debounce timer on power up avoids reporting the TCP reset that occurs as ane error
function ClearDebounce()
	PowerOnDebounce = false
end
-------------------------------------------------------------------------------
-- Device functions
-------------------------------------------------------------------------------
function Query(cmd)
	Send({
		Command = cmd.Command .. "?",
		Data = cmd.Data
	})
end

local error_codes = {
  [0] = 'P3K_NO_ERROR',
  [1] = 'ERR_PROTOCOL_SYNTAX',
  [2] = 'ERR_COMMAND_NOT_AVAILABLE',
  [3] = 'ERR_PARAMETER_OUT_OF_RANGE',
  [4] = 'ERR_UNAUTHORIZED_ACCESS',
  [5] = 'ERR_INTERNAL_FW_ERROR',
  [6] = 'ERR_BUSY',
  [7] = 'ERR_WRONG_CRC',
  [8] = 'ERR_TIMEDOUT',
  [9] = 'ERR_RESERVED',
  [10] = 'ERR_FW_NOT_ENOUGH_SPACE',
  [11] = 'ERR_FS_NOT_ENOUGH_SPACE',
  [12] = 'ERR_FS_FILE_NOT_EXISTS',
  [13] = 'ERR_FS_FILE_CANT_CREATED',
  [14] = 'ERR_FS_FILE_CANT_OPEN',
  [15] = 'ERR_FEATURE_NOT_SUPPORTED',
  [16] = 'ERR_RESERVED_2',
  [17] = 'ERR_RESERVED_3',
  [18] = 'ERR_RESERVED_4',
  [19] = 'ERR_RESERVED_5',
  [20] = 'ERR_RESERVED_6',
  [21] = 'ERR_PACKET_CRC',
  [22] = 'ERR_PACKET_MISSED',
  [23] = 'ERR_PACKET_SIZE',
  [24] = 'ERR_RESERVED_7',
  [25] = 'ERR_RESERVED_8',
  [26] = 'ERR_RESERVED_9',
  [27] = 'ERR_RESERVED_10',
  [28] = 'ERR_RESERVED_11',
  [29] = 'ERR_RESERVED_12',
  [30] = 'ERR_EDID_CORRUPTED',
  [31] = 'ERR_NON_LISTED',
  [32] = 'ERR_SAME_CRC',
  [33] = 'ERR_WRONG_MODE',
  [34] = 'ERR_NOT_CONFIGURED'
}

function PrintError(msg)
	if error_codes[tonumber(msg)]~=nil then
  print("PrintError exists")
		if DebugFunction then print('ERROR: '..error_codes[tonumber(msg)].." CurrentCommand: "..CurrentCommand) end
    if tonumber(msg) == 2 then --ERR_COMMAND_NOT_AVAILABLE
		  --if DebugFunction then print('ERR_COMMAND_NOT_AVAILABLE') end
      local m_ = CurrentCommand:match("^#([^ %?]+).*$")
      --local ResponseObj = { ['DeviceID']=m1_, ['Command']=m2_, ['Data']=m3_ }
      --if DebugFunction then print('Command: '..m_) end
			for k,v in pairs(Request) do
      if v.Command == m_ then 
          print('flagging "'..m_..'" as Unsupported')
          v['Unsupported'] = true
        end
			end    
    end
  end
end

local current_source = {}

function SetVideoChoicesFeedback(output)
	--if DebugFunction and output==1 then print("SetVideoChoicesFeedback("..output..")") end
	current_source[Layers.Video] 				 = current_source[Layers.Video] or {}
	current_source[Layers.Video][output] = current_source[Layers.Video][output] or 0
	if Controls["output_"..output.."-source"] then
    if current_source[Layers.Video][output]=='0' then
      Controls["output_"..output.."-source"].String = NoSourceName
    else
      Controls["output_"..output.."-source"].String = Controls["input_"..current_source[Layers.Video][output].."-name"].String		
    end
  end
end

function UpdateVideoChoices()
	if not UpdatingVideoChoices then
		UpdatingVideoChoices = true 
		Timer.CallAfter(function()
			if DebugFunction then print("UpdateVideoChoices()") end
			local InputChoices = {}
			table.insert(InputChoices, NoSourceName)
			for i=1, Properties['Input Count'].Value do
				table.insert(InputChoices, Controls["input_"..i.."-name"].String)
			end
			for o=1, Properties['Output Count'].Value do
				Controls["output_"..o.."-source"].Choices = InputChoices
				SetVideoChoicesFeedback(o)
			end
			UpdatingVideoChoices = false
		end		
		, 1)
	end
end

local function SetAudRouteFeedback(output, output_layer, input, input_layer) -- Audio.Layers = { 0=Analog, 1=Digital)
	if DebugFunction then print("SetAudRouteFeedback(output: "..output.." layer: "..output_layer..",  index: "..input.." layer: "..input_layer..")") end
	if output~=nil and input~=nil then
		local in_ = tonumber(input)
		local out_ = tonumber(output)
		local in_layer_ = tonumber(input_layer)
		local out_layer_ = tonumber(output_layer)
		if out_~=nil and out_ <= Properties['Output Count'].Value and in_~=nil and in_ <= Properties['Input Count'].Value then
			for i=1, Properties['Input Count'].Value do
				--can't have both an analog and digital input going to a single output so need to update feedback for both audio input layers
				local ana_in_id_ = string.format("aud-ana-input_%d-%soutput_%d", i, out_layer_==AudioLayer.Analog and "ana-" or "", out_)
				local dig_in_id_ = string.format("aud-input_%d-%soutput_%d"    , i, out_layer_==AudioLayer.Analog and "ana-" or "", out_)
				if DebugFunction and in_==i then
					print('ana_in_id_: '..ana_in_id_)
					print('dig_in_id_: '..dig_in_id_)
				end 
				Controls[ana_in_id_].Boolean = (in_==i and in_layer_==AudioLayer.Analog) 
				Controls[dig_in_id_].Boolean = (in_==i and in_layer_==AudioLayer.Digital) 
			end
		end
	end
end

function SetRouteFeedback(layer, output, input)
	if DebugFunction then print("SetRouteFeedback(layer: "..layer..", output: "..output..", index: "..input..")") end
	--if DebugFunction then print('Handling Route: "'..msg["Data"]..'"') end
	if layer==Layers.Audio then
		SetAudRouteFeedback(output, AudioLayer.Digital, input, AudioLayer.Digital)
	else
		if output~=nil and input~=nil then
			local in_ = tonumber(input)
			local out_ = tonumber(output)
			current_source[layer] = current_source[layer] or {}
			current_source[layer][output] = input
			if out_~=nil and out_ <= Properties['Output Count'].Value and in_~=nil and in_ <= Properties['Input Count'].Value then
				for i=1, Properties['Input Count'].Value do
          if Controls["vid-input_"..i.."-output_" ..output] then
            if layer==Layers.Video then
              Controls["vid-input_"..i.."-output_" ..output].Boolean = (in_==i) 
            elseif layer==Layers.Audio then    
              Controls["aud-input_"..i.."-output_" ..output].Boolean = (in_==i) 
            end   
          end
				end
			end
			if layer==Layers.Video then SetVideoChoicesFeedback(output) end
		end
	end
end

--  Device Request and Data handlers

--[[ Test the device once for
	Model Number
	Device Name
	Model Name
	Serial Number
	SW Revision
]]
-- Initial data grab from device
function GetDeviceInfo()
	if DebugFunction then print("GetDeviceInfo() Called") end
	if Properties["Get Device Info"].Value then
		Query( Request["DeviceInfo"] ) -- gets "IPAddress", "UDPPort", "TCPPort", "MACAddress", "Model", and "DeviceName" 
		if(Controls["SerialNumber"].String == "") then Query( Request["SerialNumber"] )  end
		if(Controls["DeviceFirmware"].String == "") then Query( Request["DeviceFirmware"] )  end
	end
	Query( Request["AudioFollowVideo"] )
	QueryLabels()
	if Properties['Model'].Value=='Other' then QueryLevelRanges() end
end

function QueryLabels()
	if DebugFunction then print("QueryLabels())") end
	for i=1, Properties['Input Count'].Value do
		local cmd_ = {Command = Request["Label"].Command, Data = '0,'..i }
		--if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data..',Input '..i)) end
		if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, '0,'..i..',on,INPUT '..i)) end
		Query(cmd_)
	end
	for o=1, Properties['Output Count'].Value do
		local cmd_ = {Command = Request["Label"].Command, Data = '1,'..o }
		if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, '1,'..o..',on,OUTPUT '..o)) end
		Query(cmd_)
	end
end

function QueryLevelRanges()
	if DebugFunction then print("QueryLevelRanges())") end
	for i=1, Properties['Input Count'].Value do
		local cmd_ = {Command = Request["AudioLevelRange"].Command, Data = '0,'..i }
		if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data..',-83,24')) end
		Query(cmd_)
	end
	for o=1, Properties['Output Count'].Value do
		local cmd_ = {Command = Request["AudioLevelRange"].Command, Data = '1,'..o }
		if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data..',-83,24')) end
		Query(cmd_)
	end
end

function QueryRoutes()
	if DebugFunction then print("QueryRoutes()") end		
	Query({Command = Request["Route"].Command, Data = QueryRouteType ..',*'})
end

--[[  Response Data parser
	
	All response commands are hex bytes of the format
	Header    DeviceID   Constant   CommandName  Parameters   Suffix
		~      nn      		@  		<Command>    <Parameter>  0x0d0x0a

	Read until a header is found, then:
	1. Define a data object
	2. Parse the command, DeviceID, and ack into the structure
	3. Parse the data into an array
	4. Push the data object into a handler based on the command

	Recursively call if there is more data after the suffix. Stuff incomplete messages in the buffer
]]
function ParseResponse(msg)
	--if DebugFunction then print("ParseResponse() Called") end
	Controls["ReceivedString"].String = msg
	local delimPos_ = msg:find("\x0d\x0a")
	local valid_ = msg:len()>0 and delimPos_~=nil
	--Message is too short, buffer the chunk and wait for more
	if not valid_ then 
		print("invalid: "..msg)
		DataBuffer = DataBuffer .. msg
		--Message doesn't start at begining.  Find the correct start then parse from there
	elseif msg:byte(1) ~= string.byte('~') then
		local i=msg:find('~') 
		if i ~= nil then
			ParseResponse( msg:sub(i,-1) )
		else
			DataBuffer = DataBuffer .. msg
		end
	else
		--Pack the data for the handler
		local m1_,m2_,m3_ = msg:match('~([^@]+)@([^ ]*) ([^\x0d]+)\x0d\x0a')
		if m1_==nil then  m1_,m2_,m3_= msg:match('~([^@]+)@(%a+)(%d+)\x0d\x0a') end
		local ResponseObj = { ['DeviceID']=m1_, ['Command']=m2_, ['Data']=m3_ }
		if DebugFunction then print('DeviceID: '..m1_..', Command: "'..m2_..'", data: "'..m3_..'"') end
		--if DebugFunction then print('cResponseObj[DeviceID]:'..ResponseObj['DeviceID']) end
		if ResponseObj['Command']:len()==0 and ResponseObj['Data']~=nil and ResponseObj['Data']:lower() == 'ok' then
			if DebugFunction then print('device id set: '..ResponseObj['DeviceID']) end
			Controls['DeviceID'].Value = tonumber(ResponseObj['DeviceID'])
		elseif Controls['DeviceID'].Value == nil then
			if DebugFunction then print('ResponseObj[DeviceID]:'..tonumber(ResponseObj['DeviceID'])) end
			Controls['DeviceID'].Value = tonumber(ResponseObj['DeviceID'])
			if DebugFunction then print('device id is nil, set to "'..tostring(Controls['DeviceID'].Value)..'"') end
		end  
		
		if Controls['DeviceID'].Value == tonumber(ResponseObj['DeviceID']) then
			--if DebugFunction then print('device id "'..tostring(Controls['DeviceID'].Value)..'" matches') end
			HandleResponse(ResponseObj)    
		else
			if DebugFunction then print('device id "'..ResponseObj['DeviceID']..'" does not match "'..tostring(Controls['DeviceID'].Value)..'"') end
		end

		--Re-process any remaining data
		if delimPos_~=nil and (delimPos_+2 < msg:len()) then
			ParseResponse( msg:sub(delimPos_+2,-1) )
		end
		end
end

-- Handler for good data from interface
function HandleResponse(msg)
	if DebugFunction then print('HandleResponse('..msg.Command..') Called, data: "'..msg.Data..'"') end
	
  local match_ = msg["Data"]:match("ERR(%d+)")
	if match_ then
		if DebugFunction then PrintError(match_) end
    return
  end

	local vals_ = {}
	for g in string.gmatch(msg["Data"], "[^,]+") do
		table.insert(vals_, g)
	end

	local io_ = { ['0'] = 'Input', ['1'] = 'Output'}

	--Beacon info
	if msg.Command==Request["DeviceInfo"].Command then
		if DebugFunction then 
			if vals_[1]~=nil then print("port_id: "..vals_[1]) end
			if vals_[2]~=nil then print("IPAddress: "..vals_[2]) end
			if vals_[3]~=nil then print("udp_port: "..vals_[3]) end
			if vals_[4]~=nil then print("tcp_port: "..vals_[4]) end
			if vals_[5]~=nil then print("MACAddress: "..vals_[5]) end
			if vals_[6]~=nil then print("ModelName: "..vals_[6]) end
			if vals_[7]~=nil then print("DeviceName: "..vals_[7]) end
		end
		if vals_[2]~=nil then Controls["IPAddress"].String = vals_[2] end
		if vals_[4]~=nil then Controls["Port"].String = vals_[4] end
		if vals_[5]~=nil then Controls["MACAddress"].String = vals_[5] end
		if vals_[6]~=nil then Controls["ModelName"].String = vals_[6] end
		if vals_[7]~=nil then Controls["DeviceName"].String = vals_[7] end

	--Hostname
	elseif msg.Command==Request["HostName"].Command then
		if DebugFunction then print("HostName: "..msg["Data"]) end
		Controls["HostName"].String = msg["Data"]
	--Firmware
	elseif msg.Command==Request["DeviceFirmware"].Command then
		if DebugFunction then print("DeviceFirmware: "..msg["Data"]) end
		Controls["DeviceFirmware"].String = msg["Data"]
	--SW Version
	elseif msg.Command==Request["SerialNumber"].Command then
		if DebugFunction then print("SerialNumber: "..msg["Data"]) end
		Controls["SerialNumber"].String = msg["Data"]

	elseif msg.Command==Request["IPAddress"].Command then
		if DebugFunction then print("IPAddress: "..msg["Data"]) end
		Controls["IPAddress"].String = msg["Data"]
		
	elseif msg.Command==Request["MACAddress"].Command then
		if DebugFunction then print("MACAddress: "..msg["Data"]) end
		Controls["MACAddress"].String = msg["Data"]

	elseif msg.Command==Request["EthernetPort"].Command then
		if DebugFunction then print("EthernetPort: "..msg["Data"]) end
		Controls["Port"].String = msg["Data"]
		
	elseif msg.Command==Request["Model"].Command then
		if DebugFunction then print("ModelName: "..msg["Data"]) end
		Controls["ModelName"].String = msg["Data"]


	elseif msg.Command==Request["BuildDate"].Command then
		if DebugFunction then print("BuildDate: "..msg["Data"]) end
		
	elseif msg.Command==Request["DipSwitch"].Command then
		if DebugFunction then print("DipSwitch: "..msg["Data"]) end

	elseif msg.Command==Request["FPGAVersion"].Command then
		if DebugFunction then print("FPGAVersion: "..msg["Data"]) end

	elseif msg.Command==Request["NetworkConfig"].Command then
		if DebugFunction then print("NetworkConfig: "..msg["Data"]) end
		if DebugFunction then 
			if vals_[1]~=nil then print("NetworkAdaptor: "..vals_[1]) end 
			if vals_[2]~=nil then print("IPAddress: "..vals_[2])  end
			if vals_[3]~=nil then print("SubnetMask: "..vals_[3]) end
			if vals_[4]~=nil then print("Gateway: "..vals_[4]) end
			if vals_[5]~=nil then print("dns1: "..vals_[5]) end
			if vals_[6]~=nil then print("dns2: "..vals_[6]) end
		end
		if vals_[2]~=nil then Controls["IPAddress"].String = vals_[2] end

	elseif msg.Command==Request["DHCP"].Command then
		if DebugFunction then print("DHCP: "..msg["Data"]) end
		
	elseif msg.Command==Request["Gateway"].Command then
		if DebugFunction then print("Gateway: "..msg["Data"]) end
		
	elseif msg.Command==Request["NetMask"].Command then
		if DebugFunction then print("SubnetMask: "..msg["Data"]) end
		
	elseif msg.Command==Request["ProtocolVersion"].Command then
		if DebugFunction then print("ProtocolVersion: "..msg["Data"]) end
		
	elseif msg.Command==Request["Time"].Command then
		if DebugFunction then print("Time: "..msg["Data"]) end
		
	elseif msg.Command==Request["TimeZone"].Command then
		if DebugFunction then print("TimeZone: "..msg["Data"]) end
		
	elseif msg.Command==Request["TimeServer"].Command then
		if DebugFunction then print("TimeServer: "..msg["Data"]) end

	elseif msg.Command==Request["Error"].Command then
		if DebugFunction then print("Error: "..msg["Data"]) end
		PrintError(msg["Data"])

	--Authentication
	elseif msg.Command==Request["Login"].Command then
		if DebugFunction then print("Username: "..msg["Data"]) end
		Controls["Username"].String = msg["Data"]	

	elseif msg.Command==Request["Password"].Command then
		--if DebugFunction then print("Password: "..msg["Data"]) end
		if DebugFunction then 
			if vals_[1]~=nil then print("login_level: "..vals_[1]) end
			if vals_[2]~=nil then print("password: "..vals_[2]) end
		end
		if vals_[1]~=nil then Controls["Username"].String = vals_[1] end
		if vals_[2]~=nil then Controls["Password"].String = vals_[2] end

	elseif msg.Command==Request["Security"].Command then
		if DebugFunction then print("Security: "..msg["Data"]) end
		--Controls["Security"].String = msg["Data"]	

	elseif msg.Command==Request["Logout"].Command then
		if DebugFunction then print("Logout: "..msg["Data"]) end
		--if msg["Data"]:lower()=='ok'
	
	elseif msg.Command==Request["Label"].Command then
		if DebugFunction then print("Label: "..msg["Data"]) end
		local io_ = vals_[1]=='0' and 'in' or 'out'
    if Controls[io_ .. "put_" .. vals_[2] .. "-name"] then
		  Controls[io_ .. "put_" .. vals_[2] .. "-name"].String = vals_[4]
    end
		if io_=='in' then UpdateVideoChoices() end
	--Audio
	elseif msg.Command==Request["AudioEmbedding"].Command then
		if DebugFunction then print("Embed: "..msg["Data"]) end

	elseif msg.Command==Request["AudioLevelRange"].Command then
		if DebugFunction then print("AudioLevelRange: "..msg["Data"]) end
		if #vals_>3 then
			if DebugFunction then print(io_[vals_[1]]..": "..vals_[2].." min: "..vals_[3].." max: "..vals_[4]) end
			--helper.PrintControl(Controls["input_"..vals_[2].."-level"])
			if vals_[1] == '0' and tonumber(vals_[2]) <= Properties['Input Count'].Value then
				Inputs = Inputs or {}
				Inputs[tonumber(vals_[2])] = Inputs[tonumber(vals_[2])] or {}
				Inputs[tonumber(vals_[2])].MinValue = tonumber(vals_[3])
				Inputs[tonumber(vals_[2])].MaxValue = tonumber(vals_[4])
				--print("[input_"..vals_[2].."-level].MinValue: "..Controls["input_"..vals_[2].."-level"].MinValue)
				--print("[input_"..vals_[2].."-level].MaxValue: "..Controls["input_"..vals_[2].."-level"].MaxValue)
				--Controls["input_"..vals_[2].."-level"].MaxValue = tonumber(vals_[4])
			elseif vals_[1] == '1' and tonumber(vals_[2]) <= Properties['Output Count'].Value then
				Outputs = Outputs or {}
				Outputs[tonumber(vals_[2])] = Outputs[tonumber(vals_[2])] or {}
				Outputs[tonumber(vals_[2])].MinValue = tonumber(vals_[3])
				Outputs[tonumber(vals_[2])].MaxValue = tonumber(vals_[4])
				--Controls["output_"..vals_[2].."-level"].MinValue = tonumber(vals_[3])
				--Controls["output_"..vals_[2].."-level"].MaxValue = tonumber(vals_[4])
			end
		end

	elseif msg.Command==Request["AutoSwitchMode"].Command then
		if DebugFunction then print("AutoSwitchMode: "..msg["Data"]) end

	elseif msg.Command==Request["AutoSwitchTimeout"].Command then
		if DebugFunction then print("AutoSwitchTimeout: "..msg["Data"]) end
		
	elseif msg.Command==Request["Mute"].Command then
		if DebugFunction then print("Mute: "..msg["Data"]) end
		if DebugFunction and #vals_>2 then 
			print("output: "..vals_[1].." mute: "..vals_[2]) 
		end
		if #vals_>1 and tonumber(vals_[1]) <= Properties['Output Count'].Value then
			if Controls["output_"..vals_[1].."-mute"] then 
			  Controls["output_"..vals_[1].."-mute"].Boolean = (vals_[2]=="1") 
      end
		end
		
	elseif msg.Command==Request["AudioSignalPresent"].Command then
		if DebugFunction then print("AudioSignalPresent: "..msg["Data"]) end
		if DebugFunction and #vals_>1 then 
			print("aud-input_"..vals_[1].."-signal: "..vals_[2]) 
		end
		if Controls["input_"..vals_[1].."-signal"] then
			Controls["input_"..vals_[1].."-signal"].Boolean = (vals_[2]=='1') 
		end
		
	elseif msg.Command==Request["AudioLevel"].Command then
		if DebugFunction then print("AudioLevel: "..msg["Data"]) end
		local layerName_ = vals_[1]=="0" and "input" or "output"
		if DebugFunction and #vals_>2 then 
			print(layerName_.."_"..vals_[2].."-level: "..vals_[3]) 
		end
		if #vals_>2 and Controls[layerName_.."_"..vals_[2].."-level"] then
			Controls[layerName_.."_"..vals_[2].."-level"].Value = tonumber(vals_[3]) 
		end
		
	elseif msg.Command==Request["Volume"].Command then
		if DebugFunction then print("Volume: "..msg["Data"]) end
		local val_ = tonumber(vals_[2])  --TODO: convert this to a log
		if Controls["output_"..vals_[1].."-level"] then
      if val_ > 50 then
        Controls["output_"..vals_[1].."-level"].Value = (tonumber(vals_[2])-50)/2 -- 51 to 100 is (1 to 24)
      else
        Controls["output_"..vals_[1].."-level"].Value = (tonumber(vals_[2])-50)*83/51 -- 0 to 50 is (-83 to 0)
      end
    end
	elseif msg.Command==Request["AudioFollowVideo"].Command then
		if DebugFunction then print("AudioFollowVideo: "..msg["Data"]) end
		Controls["AFV"].Boolean = (msg.Data=='0')
		for o = 0, Properties['Output Count'].Value do
			for i = 1, Properties['Input Count'].Value do
				Controls["aud-input_"     .. i .. "-output_"     .. o].IsInvisible = Controls["AFV"].Boolean
				Controls["aud-ana-input_" .. i .. "-output_"     .. o].IsInvisible = Controls["AFV"].Boolean
				Controls["aud-input_"     .. i .. "-ana-output_" .. o].IsInvisible = Controls["AFV"].Boolean
				Controls["aud-ana-input_" .. i .. "-ana-output_" .. o].IsInvisible = Controls["AFV"].Boolean
			end
		end

	--Video
	elseif msg.Command==Request["SignalPresent"].Command then
		if DebugFunction then print("SignalPresent: "..msg["Data"]) end
		if DebugFunction and #vals_>1 then 
			print("vid-input_"..vals_[1].."-signal: "..vals_[2]) 
		end
		if Controls["vid-input_"..vals_[1].."-signal"] then
			Controls["vid-input_"..vals_[1].."-signal"].Boolean = (vals_[2]=='1') 
		end

	elseif msg.Command==Request["HPD"].Command then
		if DebugFunction then print("HPD: "..msg["Data"]) end

	elseif msg.Command==Request["HDCPMode"].Command then
		if DebugFunction then print("HDCPMode: "..msg["Data"]) end

	elseif msg.Command==Request["HDCPStatus"].Command then
		if DebugFunction then print("HDCPStatus: "..msg["Data"]) end

	elseif msg.Command==Request["LockEDID"].Command then
		if DebugFunction then print("LockEDID: "..msg["Data"]) end

	elseif msg.Command==Request["VGAPhase"].Command then
		if DebugFunction then print("VGAPhase: "..msg["Data"]) end

	elseif msg.Command==Request["VideoMute"].Command then
		if DebugFunction then print("VideoMute: "..msg["Data"]) end
		if DebugFunction and #vals_>2 then 
			print("output: "..vals_[1].." video mute: "..vals_[2]) 
		end
		if Controls["output_"..vals_[1].."-disable"] then
			Controls["output_"..vals_[1].."-disable"].Boolean = (vals_[2]=="1") --0:disabled, 1:enabled, 2:blank(not all models)
		end

	elseif msg.Command==Request["Route"].Command then -- "ROUTE 1,2,3" (laver, output, input) or "ROUTE 1,1,1,1,1,1,1,1" (each val is an output-it could be any layer though)
		-- best off not to use this because the response is ambiguous
		-- it could be a single route with layer data or all routes with no reference to which payer
		if #vals_== 3 then SetRouteFeedback(vals_[1], vals_[2], vals_[3])
		else
			for out_=1, #vals_ do SetRouteFeedback(QueryRouteType, out_, vals_[out_]) end			
			QueryRouteType = QueryRouteType == Layers.Video and Layers.Audio or Layers.Video; --toggle the type of route to query next time
		end

	elseif msg.Command==Request["AvRoute"].Command then 
		local in_, out_ = string.match(msg["Data"], "(%d+)>(%d+)") -- "AV 1>2"
		SetRouteFeedback(Layers.Video, out_, in_)
		SetRouteFeedback(Layers.Audio, out_, in_)

	elseif msg.Command==Request["VideoRoute"].Command then
		local in_, out_ = string.match(msg["Data"], "(%d+)>(%d+)") -- "VID 1>2"
		SetRouteFeedback(Layers.Video, out_, in_)

	elseif msg.Command==Request["AudioRoute"].Command then
		local in_, out_ = string.match(msg["Data"], "(%d+)>(%d+)") -- "AUD 1>2"
		SetRouteFeedback(Layers.Audio, out_, in_)
		
	elseif msg.Command==Request["ExternalAudio"].Command then -- "EXT-AUD 0,2,0,3" -<output type>,<output>,<input type>,<input>
		local dest_layer = vals_[1] -- ana=0, dig=1
		local dest    	 = vals_[2]
		local src_layer  = vals_[3] -- ana=0, dig=1
		local src 		   = vals_[4]
		SetAudRouteFeedback(dest, dest_layer, src, src_layer)
	else
			print("Response not handled")
	end
end

-------------------------------------------------------------------------------
-- Device routing functions
-------------------------------------------------------------------------------
local function SetAvRoute(dest, src, state) -- "AV 1>2"
	if(state == 0) then
		if DebugFunction then print("Disconnecting src "..src.." from "..dest) end
		src = 0
	else
		if DebugFunction then print("Send src " .. src .. " to dest " .. dest) end
	end
	if dest == 0 then dest = '*' end -- all
	local cmd_ = Controls['AFV'].Boolean and Request["AvRoute"] or Request["VideoRoute"]
	cmd_.Data = src..'>'.. dest
	Send(cmd_)
	if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end

local function SetRoute(layer, dest, src, state) -- "ROUTE 0,1,2"
	if(state == 0) then
		if DebugFunction then print("Disconnecting layer " .. layer .. " src "..src.." from "..dest) end
			src = 0
		else
		if DebugFunction then print("Send layer " .. layer .. " from src " .. src .. " to dest " .. dest) end
	end
	if dest == 0 then dest = '*' end
	local cmd_ = Request["Route"]
	cmd_.Data = layer ..','..dest..','.. src
	Send(cmd_)
	if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end

local function SetAudRoute(dest, dest_layer, src, src_layer, state)
	if(state == 0) then
		src = 0 --dest = "x"
		if DebugFunction then print("Disconnecting audio src from all") end
	else
		if DebugFunction then print("Send audio src " .. src .. " to dest " .. dest) end
	end
	if dest == 0 then dest = '*' end
	local cmd_ = {}
	if dest_layer==AudioLayer.Digital and src_layer==AudioLayer.Digital then
		cmd_ = Request["AudioRoute"] -- "AUD 1>2"
		cmd_.Data = src..'>'.. dest
	else
		cmd_ = Request["ExternalAudio"] -- "EXT-AUD 0,2,0,3" -<output type>,<output>,<input type>,<input>
		cmd_.Data = dest_layer..','..dest..','..src_layer..','..src
	end
	Send(cmd_)
	if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end

local function SetAudioFollowVideo(state)
	if DebugFunction then print("Send Audio follow video: "..tostring(state)) end
	local cmd_ = Request["AudioFollowVideo"]
	cmd_.Data = state and "0" or "1"
	Send(cmd_)
	if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end
	
local function SetFrontPanelLock(state)
	if DebugFunction then print("Lock front panel: "..tostring(state)) end
	local cmd_ = Request["LockFrontPanel"]
	cmd_.Data = state and "1" or "0"
	Send(cmd_)
	if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end

local function SetInputLevel(index, value)
	if DebugFunction then print("Set input " .. index .. " level to " .. value) end
	local cmd_ = Request["AudioLevel"]
	local value_ = tonumber(value)==nil and value or math.floor(value)
	cmd_.Data = '0' ..','..index..','.. value
	Send(cmd_)
	--if SimulateFeedback and tonumber(value)~=nil then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end

local function SetOutputLevel(index, value)
	if DebugFunction then print("Set output " .. index .. " level to " .. value) end
	--local cmd_ = Request["AudioLevel"]
	--cmd_.Data = '1' ..','..index..','.. math.floor(value)
	local cmd_ = Request["Volume"]
	if value > 0 then -- 1-24 becomes 51-100
		cmd_.Data = index..','.. math.floor(value*2+50)
	else 							-- -83-0 becomes 0-50
		cmd_.Data = index..','.. math.floor((value+83)*50/83)
	end
	Send(cmd_)
	--if SimulateFeedback and tonumber(value)~=nil then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end

local function SetOutputMute(index, value)
	if DebugFunction then print("Set output " .. index .. " mute to " .. tostring(value)) end
	local cmd_ = Request["Mute"]
	cmd_.Data = index..','.. (value and '1' or '0')
	Send(cmd_)
	--if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end

local function SetOutputDisable(index, value)
	if DebugFunction then print("Set output " .. index .. " video mute to " .. tostring(value)) end
	local cmd_ = Request["VideoMute"]
	cmd_.Data = index..','.. (value and '1' or '0') -- 0:disabled, 1:enabled, 2:blank(not all models)

	Send(cmd_)
	--if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end

local function SetOutputLabel(index, value)
	if DebugFunction then print("Set output " .. index .. " label to " .. value) end
	local cmd_ = Request["Label"]
	cmd_.Data = '1,'.. index .. ',on,' .. value
	--cmd_.Data = '1,'.. index .. ',1,' .. value -- the extra 1 is for enable custom label
	Send(cmd_)
	--if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end

local function SetInputLabel(index, value)
	if DebugFunction then print("Set output " .. index .. " label to " .. value) end
	local cmd_ = Request["Label"]
	cmd_.Data = '0,'.. index .. ',on,' .. value
	--cmd_.Data = '0,'.. index .. ',1,' .. value -- the extra 1 is for enable custom label
	Send(cmd_)
	--if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
end


function Connected()
	if DebugFunction then print("Connected() Called") end
	CommunicationTimer:Stop()
	Heartbeat:Start(PollRate)
	CommandProcessing = false
	if Controls["DeviceName"].String == "" then	GetDeviceInfo() end
	QueryRoutes()
	SendNextCommand()
	end


--[[  Communication format
	All commands are hex bytes of the format:
	Header   CommandName   Constant   Parameters   Suffix
		#     <Command>       0x20    <Data>  0x0d

	Both Serial and TCP mode must contain functions:
	Connect()
	And a receive handler that passes data to ParseData()
]]

-- Take a request object and queue it for sending.  Object format is of:
--  { Command=string, Data={string} }
function Send(cmd, sendImmediately) 
  if cmd['Unsupported'] then
    if DebugFunction then print("DoSend("..cmd.Command..") command not supported") end
  else
    local value = "#".. cmd.Command .. " " .. cmd.Data
    if DebugFunction then print("DoSend("..value..") Called") end
    value = value .. '\x0D'
    --Check for if a command is already queued
    for i, val in ipairs(CommandQueue) do
      if(val == value)then
        --Some Commands should be sent immediately
        if sendImmediately then
          --remove other copies of a command and move to head of the queue
          table.remove(CommandQueue,i)
          if DebugTx then print("Sending: "..GetPrintableHexString(value)) end
          table.insert(CommandQueue,1,value)
        end
        return
      end
    end
    --Queue the command if it wasn't found
    table.insert(CommandQueue,value)
    SendNextCommand()
  end
end

--Timeout functionality
-- Close the current and start a new connection with the next command
-- This was included due to behaviour within the Comms Serial; may be redundant check on TCP mode
CommunicationTimer.EventHandler = function()
	if DebugFunction then print("CommunicationTimer.EventHandler") end
	ReportStatus("MISSING","Communication Timeout")
	CommunicationTimer:Stop()
	CommandProcessing = false
	SendNextCommand()
end 

print(ConnectionType.." Mode Initializing...")
	--  Serial mode Command function  --
if ConnectionType == "Serial" then
	-- Create Serial Connection
	Comms = SerialPorts[1]
	Baudrate, DataBits, Parity = 9600, 8, "N"

	--Send the next command off the top of the queue
	function SendNextCommand()
		--if DebugFunction then print("SendNextCommand() Called") end
		if CommandProcessing then
			-- Do Nothing
		elseif #CommandQueue > 0 then
			CommandProcessing = true
		  CurrentCommand = table.remove(CommandQueue,1)
			if DebugTx then print("Sending: "..GetPrintableHexString(CurrentCommand)) end
			Comms:Write( CurrentCommand )
			CommunicationTimer:Start(CommandTimeout)
		else
			CommunicationTimer:Stop()
		end
	end

	function Disconnected()
		if DebugFunction then print("Disconnected() Called") end
		CommunicationTimer:Stop() 
		CommandQueue = {}
		Heartbeat:Stop()
	end
	
		-- Clear old and open the socket, sending the next queued command
	function Connect()
		if DebugFunction then print("Connect() Called") end
		Comms:Close()
		Comms:Open(Baudrate, DataBits, Parity)
	end

	-- Handle events from the serial port
	Comms.Connected = function(serialTable)
		if DebugFunction then print("Connected handler called Called") end
		ReportStatus("OK","")
		Connected()
	end
	
	Comms.Reconnect = function(serialTable)
		if DebugFunction then print("Reconnect handler called Called") end
		Connected()
	end
	
	Comms.Data = function(serialTable, data)
		ReportStatus("OK","")
		CommunicationTimer:Stop() 
		CommandProcessing = false
		local msg = DataBuffer .. Comms:Read(1024)
		DataBuffer = "" 
		if DebugTx then print("Received: "..GetPrintableHexString(msg)) end
		ParseResponse(msg)
		SendNextCommand()
	end
	
	Comms.Closed = function(serialTable)
		if DebugFunction then print("Closed handler called Called") end
		Disconnected()
		ReportStatus("MISSING","Connection closed")
	end
	
	Comms.Error = function(serialTable, error)
		if DebugFunction then print("Socket Error handler called Called") end
		Disconnected()
		ReportStatus("MISSING",error)
	end
	
	Comms.Timeout = function(serialTable, error)
		if DebugFunction then print("Socket Timeout handler called Called") end
		Disconnected()
		ReportStatus("MISSING","Serial Timeout")
	end

	--[[
	Controls["Reset"].EventHandler = function()
		if DebugFunction then print("Reset handler called Called") end
		PowerupTimer:Stop()
		ClearVariables()
		Disconnected()
		Connect()
	end
	]]
	
	--  Ethernet Command Function  --
elseif ConnectionType == "TCP" then
	IPAddress = Controls.IPAddress
	if Controls.NetworkPort.Value == 0 then Controls.NetworkPort.Value = 5000 end
	Port = Controls.NetworkPort
	-- Create Sockets
	Comms = TcpSocket.New()
	Comms.ReconnectTimeout = 5
	Comms.ReadTimeout = 10  --Tested to verify 6 seconds necessary for input switches;  Appears some TV behave mroe slowly
	Comms.WriteTimeout = 10

	--Send the next command off the top of the queue
	function SendNextCommand()
		--if DebugFunction then print("SendNextCommand() Called") end
		if CommandProcessing then
		-- Do Nothing
		elseif #CommandQueue > 0 then
			if not Comms.IsConnected then
				Connect()
			else
				CommandProcessing = true
			  CurrentCommand = table.remove(CommandQueue,1)
				if DebugTx then print("Sending: "..GetPrintableHexString(CurrentCommand)) end
				Comms:Write( CurrentCommand )
			end
		end
	end
	
	function Disconnected()
		if DebugFunction then print("Disconnected() Called") end
		if Comms.IsConnected then
			Comms:Disconnect()
		end
		CommandQueue = {}
		Heartbeat:Stop()
	end
	
	-- Clear old and open the socket
	function Connect()
		if DebugFunction then print("Connect() Called") end
		if IPAddress.String ~= "Enter an IP Address" and IPAddress.String ~= "" then
		if Comms.IsConnected then
			Comms:Disconnect()
		end
		Comms:Connect(IPAddress.String, Port.Value)
		else
			ReportStatus("MISSING","No IP Address")
		end
	end
		
	-- Handle events from the socket;  Nearly identical to Serial
	Comms.EventHandler = function(sock, evt, err)
		if DebugFunction then print("Ethernet Socket Handler Called("..tostring(evt)..")") end
		if evt == TcpSocket.Events.Connected then
			ReportStatus("OK","")
			Connected()
		elseif evt == TcpSocket.Events.Reconnect then
			--Disconnected()
	
		elseif evt == TcpSocket.Events.Data then
			ReportStatus("OK","")
			CommandProcessing = false
			TimeoutCount = 0
			local line = sock:Read(BufferLength)
			local msg = DataBuffer
			DataBuffer = "" 
			while (line ~= nil) do
				msg = msg..line
				line = sock:Read(BufferLength)
			end
			if DebugTx then print("Received: "..GetPrintableHexString(msg)) end
			ParseResponse(msg)  
			SendNextCommand()
			
		elseif evt == TcpSocket.Events.Closed then
			Disconnected()
			ReportStatus("MISSING","Socket closed")
	
		elseif evt == TcpSocket.Events.Error then
			Disconnected()
			ReportStatus("MISSING","Socket error")
	
		elseif evt == TcpSocket.Events.Timeout then
			TimeoutCount = TimeoutCount + 1
			if TimeoutCount > 3 then
				Disconnected()
				ReportStatus("MISSING","Socket Timeout")
			end
	
		else
			Disconnected()
			ReportStatus("MISSING",err)
	
		end
	end
elseif ConnectionType == "UDP" then
	IPAddress = Controls.IPAddress
	if Controls.NetworkPort.Value <= 1 then Controls.NetworkPort.Value = 50000 end
	Port = Controls.NetworkPort
	-- Create Sockets
	Comms = UdpSocket.New()

	--Send the next command off the top of the queue
	function SendNextCommand()
		--if DebugFunction then print("SendNextCommand() Called") end
		if CommandProcessing then
			-- Do Nothing
		elseif #CommandQueue > 0 then
			CommandProcessing = true
		  if IPAddress.String ~= "Enter an IP Address" and IPAddress.String ~= "" then
        --print("Sending to "..IPAddress.String..":"..Port.Value)
			  CurrentCommand = table.remove(CommandQueue,1)
				if DebugTx then print("Sending: "..GetPrintableHexString(CurrentCommand)) end
        Comms:Send(IPAddress.String, Port.Value, CurrentCommand )			
      else
        print("Address not valid, not sending!")
      end
      CommunicationTimer:Start(CommandTimeout)
		else
			CommunicationTimer:Stop()
		end
	end
	
		-- Clear old and open the socket, sending the next queued command
	function Connect()
		Comms:Close(Port.Value)
    Comms:Open("0.0.0.0", Port.Value)
    Connected()
	end
	Connect()

	function Disconnected()
		if DebugFunction then print("Disconnected() Called") end
		Comms:Close(Port.Value)
		CommandQueue = {}
		Heartbeat:Stop()
	end

	Comms.EventHandler = function(socket, packet)
		ReportStatus("OK","")
		CommunicationTimer:Stop() 
		CommandProcessing = false
		local msg = DataBuffer .. packet.Data
		DataBuffer = "" 
		if DebugTx then print("Received: "..GetPrintableHexString(msg)) end
		ParseResponse(msg)
		SendNextCommand()
	end
	
end

-------------------------------------------------------------------------------
-- Initialize
-------------------------------------------------------------------------------	
function TestFeedbacks()
	local cmd_ = Request["SignalPresent"]
	cmd_.Data = '1,1'
	ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data))

	cmd_ = Request["AudioSignalPresent"]
	cmd_.Data = '2,1'
	ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data))
	
	cmd_ = Request["AudioFollowVideo"]
	cmd_.Data = '1'
	ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data))

	cmd_ = Request["AudioFollowVideo"]
	cmd_.Data = '0'
	ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data))
--[[
	cmd_ = Request["Label"]
	for i = 1, Properties['Input Count'].Value do
		cmd_.Data = '0,'..tostring(i)..',INPUT '..i
		ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data))
	end 
	for o = 1, Properties['Output Count'].Value do
		cmd_.Data = '1,'..tostring(o)..',OUTPUT '..o
		ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data))
	end 
--]]
end

function Initialize()
	if DebugFunction then print("Initialize() Called: "..GetPrettyName()) end
	--helper.TablePrint(Controls, 1)
	-- EventHandlers
  
	Controls["IPAddress"].EventHandler = function(ctl)
		Connect()
	end
  
	Controls["NetworkPort"].EventHandler = function(ctl)
		Connect()
	end

	Controls["AFV"].EventHandler = function(ctl) 
		if DebugFunction then print("Audio follow video pressed") end
		SetAudioFollowVideo(ctl.Boolean)
	end
 
	Controls["SendString"].EventHandler = function(ctl) 
		if DebugFunction then print("SendString called: "..ctl.String) end
		local value = ctl.String .. 0x0d
		if value:sub(1,1)~='#' then value = '#' .. value end
		if DebugTx then print('Sending['..value:len()..']: '..GetPrintableHexString(value)) end
		table.insert(CommandQueue,value)
		SendNextCommand()
		if SimulateFeedback then ParseResponse(string.format("~%02X@%s\x0d\x0a", Controls['DeviceID'].Value, ctl.String:gsub('#',''))) end
	end

	Controls["LockFrontPanel"].EventHandler = function(ctl) 
		if DebugFunction then print("Lock front panel pressed") end
		SetFrontPanelLock(ctl.Boolean)
	end

	--helper.TablePrint(Properties, 1)
	if(Properties['Output Count'].Value > 0 and Properties['Input Count'].Value > 0) then
		for o = 0, Properties['Output Count'].Value do
			for i = 1, Properties['Input Count'].Value do
				-- Crosspoint EventHandlers
				Controls["vid-input_" .. i .. "-output_" .. o].EventHandler = function(ctl) 
					if DebugFunction then print("vid-input_" .. i .. "-output_" .. o .. " pressed") end
					--SetRoute(Layers.Video, o, i, ctl.Value)
					SetAvRoute(o, i, ctl.Value)
					if(o == 0) then ctl.Value = 0 end -- let the individual output buttons track state
				end

				Controls["aud-input_" .. i .. "-output_" .. o].EventHandler = function(ctl) -- digital-in to digital-out
					if DebugFunction then print("aud-input_" .. i .. "-output_" .. o .. " pressed") end
					--SetRoute(Layers.Audio, o, i, ctl.Value)
					SetAudRoute(o, AudioLayer.Digital, i, AudioLayer.Digital, ctl.Value)
				end

				Controls["aud-ana-input_" .. i .. "-output_" .. o].EventHandler = function(ctl)  -- analog-in to digital-out
					if DebugFunction then print("aud-ana-input_" .. i .. "-output_" .. o .. " pressed") end
					SetAudRoute(o, AudioLayer.Digital, i, AudioLayer.Analog, ctl.Value)
				end

				Controls["aud-input_" .. i .. "-ana-output_" .. o].EventHandler = function(ctl)  -- digital-in to analog-out
					if DebugFunction then print("aud-input_" .. i .. "-ana-output_" .. o .. " pressed") end
					SetAudRoute(o, AudioLayer.Analog, i, AudioLayer.Digital, ctl.Value)
				end

				Controls["aud-ana-input_" .. i .. "-ana-output_" .. o].EventHandler = function(ctl)  -- analog-in to analog-out
					if DebugFunction then print("aud-ana-input_" .. i .. "-ana-output_" .. o .. " pressed") end
					SetAudRoute(o, AudioLayer.Analog, i, AudioLayer.Analog, ctl.Value)
				end
			end
			
			-- Output EventHandlers
			Controls["output_".. o .."-mute"].EventHandler = function(ctl)
				if DebugFunction then print("output_".. o .."-mute pressed, Value: "..tostring(ctl.Value>0)) end
				if o>0 then SetOutputMute(o, (ctl.Value>0)) end
			end

			Controls["output_".. o .."-disable"].EventHandler = function(ctl)
				if DebugFunction then print("output_".. o .."-disable pressed, Value: "..tostring(ctl.Value>0)) end
				if o>0 then SetOutputDisable(o, (ctl.Value>0)) end
			end

			Controls["output_".. o .."-level"].EventHandler = function(ctl)
				if DebugFunction then print("output_".. o .."-level pressed, Value: "..ctl.Value) end
				if o>0 then SetOutputLevel(o, ctl.Value) end
			end

			Controls["output_".. o .."-name"].EventHandler = function(ctl)
				if DebugFunction then print("output_".. o .."-name changed, Value: "..ctl.String) end
				SetOutputLabel(o, ctl.String)
			end

			Controls["output_"..o.."-source"].EventHandler = function(ctl) 
				if DebugFunction then print("output_" .. o .. "source changed to: "..ctl.String) end
				if DebugFunction then print("output_" .. o .. "source changed to: "..ctl.Value) end
				local i = find_value(ctl.Choices, ctl.String)
				--SetRoute(Layers.Video, o, i, ctl.Value)
				SetAvRoute(o, i-1, true)
			end

		end
		
		-- Input EventHandlers
		for i = 1, Properties['Input Count'].Value do

			Controls["input_".. i .."-level"].EventHandler = function(ctl)
				if DebugFunction then print("input_".. i .."-level pressed, Value: "..ctl.Value) end
				Controls["input_".. i .."-level"].RampTime = 0
				SetInputLevel(i, ctl.Value)
			end

			Controls["input_".. i .."-level_up"].EventHandler = function(ctl)
				local state_ = ctl.Boolean and "pressed" or "released"
				if DebugFunction then print("input_".. i .."-level_up "..state_..", MaxValue: "..Controls["input_".. i .."-level"].MaxValue) end
				if ctl.Boolean then
					SetInputLevel(i, "++")
					Controls["input_".. i .."-level"].RampTime = 5
					Controls["input_".. i .."-level"].Value = Inputs[i].MaxValue
					--SetInputLevel(i, Inputs[i].MaxValue)
				else
					Controls["input_".. i .."-level"].RampTime = 0
					Controls["input_".. i .."-level"].Value = Controls["input_".. i .."-level"].Value -- need to do this or the ramp won't stopy
					SetInputLevel(i, Controls["input_".. i .."-level"].Value)
					--SetInputLevel(i, Controls["input_".. i .."-level"].Value)
				end
			end

			Controls["input_".. i .."-level_down"].EventHandler = function(ctl)
				local state_ = ctl.Boolean and "pressed" or "released"
				if DebugFunction then print("input_".. i .."-level_down "..state_) end
				if ctl.Boolean then
					SetInputLevel(i, "--")
					Controls["input_".. i .."-level"].RampTime = 5
					Controls["input_".. i .."-level"].Value = Inputs[i].MinValue
					--SetInputLevel(i, Controls["input_".. i .."-level"].MinValue)
					--SetInputLevel(i, Inputs[i].MinValue)
				else
					Controls["input_".. i .."-level"].RampTime = 0
					Controls["input_".. i .."-level"].Value = Controls["input_".. i .."-level"].Value -- need to do this or the ramp won't stopy
					SetInputLevel(i, Controls["input_".. i .."-level"].Value)
					--SetInputLevel(i, Controls["input_".. i .."-level"].Value)
				end
			end

			Controls["input_".. i .."-name"].EventHandler = function(ctl)
				if DebugFunction then print("input_".. i .."-name changed, Value: "..ctl.String) end
				SetInputLabel(i, ctl.String)
			end

		end
	end

	if System.IsEmulating then 
		--QueryRoutes()
		TestFeedbacks() 
	else
	end
	Disconnected()
	Connect()
	--GetDeviceInfo()
	Heartbeat:Start(PollRate)
end

-- Timer EventHandlers  --
Heartbeat.EventHandler = function()
	if DebugFunction then print("Heartbeat Event Handler Called - CommandQueue size: "..#CommandQueue) end
	if #CommandQueue < 1 then
		for i = 1, Properties['Input Count'].Value do
			Query({ Command=Request["SignalPresent"].Command, Data=tostring(i) })
			Query({ Command=Request["AudioSignalPresent"].Command, Data=tostring(i) })
		end
	end
end

SetupDebugPrint()
Initialize()
