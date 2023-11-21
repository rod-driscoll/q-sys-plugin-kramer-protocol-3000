
  local helper = require('helpers')

	-- Control aliases
	Status = Controls.Status
	
  local SimulateFeedback = true
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
	--Internal command timeout
	CommandTimeout = 5
	CommunicationTimer = Timer.New()
	TimeoutCount = 0

	--Hide controls that are just for pins
	--Controls["ModelNumber"].IsInvisible=true
	--Controls["PanelType"].IsInvisible=true


  	local Request = {
    	Status			={Command="",			Data=""},
    	AudioEmbedding	={Command="AUD-EMB",	Data=""},
    	AudioLevel		={Command="AUD-LVL",	Data=""},
    	AudioLevelRange	={Command="AUD-LVL-RANGE",Data=""},
    	AudioSignalPresent={Command="AUD-SIGNAL",Data=""},
    	AutoSwitchMode	={Command="AV-SW-MODE",	Data=""},
    	AutoSwitchTimeout={Command="AV-SW-TIMEOUT",Data=""},
    	DeviceInfo		={Command="BEACON-INFO",Data=""},
    	BuildDate		={Command="BUILD-DATE",	Data=""},
    	CopyEDIDSet		={Command="CPEDID",		Data=""},
    	HPD				={Command="DISPLAY",	Data=""},
    	DipSwitch		={Command="DPSW-STATUS",Data=""},
    	EthernetPort	={Command="ETH-PORT",	Data=""},
    	Error			={Command="ERR",		Data=""},
    	FactoryReset	={Command="FACTORY",	Data=""},
    	FPGAVersion		={Command="FPGA-VER",	Data=""},
    	HDCPMode		={Command="HDCP-MOD",	Data=""},
    	HDCPStatus		={Command="HDCP-STAT",	Data=""},
    	Help			={Command="HELP",		Data=""},
    	LockEDID		={Command="LOCK-EDID",	Data=""},
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
    	Reset			={Command="RESET",		Data=""},
    	Route			={Command="ROUTE",		Data=""},
    	Security		={Command="SECUR",		Data=""},
    	SignalPresent	={Command="SIGNAL",		Data=""},
    	SerialNumber	={Command="SN",			Data=""},
    	Time			={Command="TIME",		Data=""},
    	TimeZone		={Command="TIME-LOC",	Data=""},
    	TimeServer		={Command="TIME-SRV",	Data=""},
    	DeviceFirmware	={Command="VERSION",	Data=""},
    	VGAPhase		={Command="VGA-PHASE",	Data=""},
    	VideoMute		={Command="VMUTE",		Data=""},
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

	function Connected()
		if DebugFunction then print("Connected() Called") end
		CommunicationTimer:Stop()
		Heartbeat:Start(PollRate)
		CommandProcessing = false
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
		if DebugFunction then print("DoSend() Called") end
		local value = "#".. cmd.Command .. " " .. cmd.Data .. 0x0d
	
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

	--Timeout functionality
	-- Close the current and start a new connection with the next command
	-- This was included due to behaviour within the Comms Serial; may be redundant check on TCP mode
	CommunicationTimer.EventHandler = function()
	  if DebugFunction then print("CommunicationTimer Event (timeout) Called") end
	  ReportStatus("MISSING","Communication Timeout")
	  CommunicationTimer:Stop()
	  CommandProcessing = false
	  SendNextCommand()
	end 

  	--  Serial mode Command function  --
	if ConnectionType == "Serial" then
		print("Serial Mode Initializing...")
		-- Create Serial Connection
		Comms = SerialPorts[1]
		Baudrate, DataBits, Parity = 9600, 8, "N"

		--Send the display the next command off the top of the queue
		function SendNextCommand()
		if DebugFunction then print("SendNextCommand() Called") end
		if CommandProcessing then
			-- Do Nothing
		elseif #CommandQueue > 0 then
			CommandProcessing = true
			if DebugTx then print("Sending: "..GetPrintableHexString(CommandQueue[1])) end
			Comms:Write( table.remove(CommandQueue,1) )
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
	else
		print("TCP Mode Initializing...")
		IPAddress = Controls.IPAddress
    	Port = Controls.Port
		-- Create Sockets
		Comms = TcpSocket.New()
		Comms.ReconnectTimeout = 5
		Comms.ReadTimeout = 10  --Tested to verify 6 seconds necessary for input switches;  Appears some TV behave mroe slowly
		Comms.WriteTimeout = 10

		--Send the display the next command off the top of the queue
		function SendNextCommand()
			if DebugFunction then print("SendNextCommand() Called") end
			if CommandProcessing then
			-- Do Nothing
			elseif #CommandQueue > 0 then
				if not Comms.IsConnected then
					Connect()
				else
					CommandProcessing = true
					if DebugTx then print("Sending: "..GetPrintableHexString(CommandQueue[1])) end
					Comms:Write( table.remove(CommandQueue,1) )
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
			if IPAddress.String ~= "Enter an IP Address" and IPAddress.String ~= "" and Port.String ~= "" then
			if Comms.IsConnected then
				Comms:Disconnect()
			end
			Comms:Connect(IPAddress.String, tonumber(Port.String))
			else
			ReportStatus("MISSING","No IP Address or Port")
			end
		end
			
		-- Handle events from the socket;  Nearly identical to Serial
		Comms.EventHandler = function(sock, evt, err)
			if DebugFunction then print("Ethernet Socket Handler Called") end
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
	
		--Ethernet specific event handlers
		Controls["IPAddress"].EventHandler = function()
			if DebugFunction then print("IP Address Event Handler Called") end
			if Controls["IPAddress"].String == "" then
			Controls["IPAddress"].String = "Enter an IP Address"
			end
			ClearVariables()
			Init()
		end

		Controls["TcpPort"].EventHandler = function()
			if DebugFunction then print("Port Event Handler Called") end
			ClearVariables()
			Init()
		end

		Controls["DeviceID"].EventHandler = function()
			if DebugFunction then print("DeviceID Event Handler Called") end
			ClearVariables()
			Init()
		end

	end

	function Query(cmd)
		Send({
			Command = cmd.Command .. "?",
			Data = cmd.Data
		})
	end

	function PrintError(msg)
		local codes_ = {
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
		if codes_[tonumber(msg)]~=nil then
			if DebugFunction then print('ERROR: '..codes_[tonumber(msg)]) end
		end
	end

	function SetRouteFeedback(layer, output, input)
  	if DebugFunction then print("SetRouteFeedback(layer: "..layer..", output: "..output..", index: "..input..")") end
    --if DebugFunction then print('Handling Route: "'..msg["Data"]..'"') end
    if output~=nil and input~=nil then
      local in_ = tonumber(input)
      local out_ = tonumber(output)
      if out_~=nil and out_ <= Properties['Output Count'].Value and in_~=nil and in_ <= Properties['Input Count'].Value then
        for i=1, Properties['Input Count'].Value do
          Controls["vid-input_"..i.."-output_" ..output].Boolean = (in_==i) 
        end
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
      QueryLevelRanges()
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

  local function QueryRoutes()
		Query({Command = Request["Route"].Command, Data = Layers.Video ..',*'})
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
		if DebugFunction then print("ParseResponse() Called") end
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
			local ResponseObj = { ['DeviceID']=m1_, ['Command']=m2_, ['Data']=m3_ }
			if DebugFunction then print('DeviceID: '..m1_..', Command: "'..m2_..'", data: "'..m3_..'"') end
			--if DebugFunction then print('cResponseObj[DeviceID]:'..ResponseObj['DeviceID']) end
			
			if ResponseObj['Command']:len()==0 and ResponseObj['Data']:lower() == 'ok' then
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
				Controls["output_"..vals_[1].."-mute"].Boolean = (vals_[2]=="1") 
			end
			
		elseif msg.Command==Request["AudioSignalPresent"].Command then
			if DebugFunction then print("AudioSignalPresent: "..msg["Data"]) end
			if DebugFunction and #vals_>1 then 
				print("aud-input_"..vals_[1].."-signal: "..vals_[2]) 
			end
			if #vals_>1 and tonumber(vals_[1]) <= Properties['Output Count'].Value then
				--Controls["input_"..vals_[1].."-signal"].Boolean = (vals_[2]=='1')
				Controls["input_"..vals_[1].."-signal"].Boolean = true
			end
			
		elseif msg.Command==Request["AudioLevel"].Command then
			if DebugFunction then print("AudioLevel: "..msg["Data"]) end
			local layerName_ = vals_[1]=="0" and "input" or "output"
			if DebugFunction and #vals_>2 then 
				print(layerName_.."_"..vals_[2].."-level: "..vals_[3]) 
			end
			if #vals_>2 then
				Controls[layerName_.."_"..vals_[2].."-level"].Value = tonumber(vals_[3]) 
			end
		
		--Video
		elseif msg.Command==Request["SignalPresent"].Command then
			if DebugFunction then print("SignalPresent: "..msg["Data"]) end
			if DebugFunction and #vals_>1 then 
				print("vid-input_"..vals_[1].."-signal: "..vals_[2]) 
			end
			if #vals_>1 and tonumber(vals_[1]) <= Properties['Output Count'].Value then
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
			if #vals_>1 and tonumber(vals_[1]) <= Properties['Output Count'].Value then
				Controls["output_"..vals_[1].."-disable"].Boolean = (vals_[2]~="1") --0:disabled, 1:enabled, 2:blank(not all models)
			end

		elseif msg.Command==Request["Route"].Command then SetRouteFeedback(vals_[1], vals_[2], vals_[3])
    else
				print("Response not handled")
		end
	end
	-------------------------------------------------------------------------------
	-- Device routing functions
	-------------------------------------------------------------------------------
	local function SetRoute(layer, dest, src, state)
		if(state == 0) then
			dest = "x"
			if DebugFunction then print("Disconnecting layer " .. layer .. " src from dest " .. dest) end
		else
			if DebugFunction then print("Send layer " .. layer .. " from src " .. src .. " to dest " .. dest) end
		end
		if dest == 0 then dest = '*' end
    local cmd_ = Request["Route"]
    cmd_.Data = layer ..','..dest..','.. src
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
    local cmd_ = Request["AudioLevel"]
    cmd_.Data = '1' ..','..index..','.. math.floor(value)
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
    cmd_.Data = index..','.. (value and '0' or '1') -- 0:disabled, 1:enabled, 2:blank(not all models)

		Send(cmd_)
    --if SimulateFeedback then ParseResponse(string.format("~%02X@%s %s\x0d\x0a", Controls['DeviceID'].Value, cmd_.Command, cmd_.Data)) end
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
  end

	function Initialize()
		if DebugFunction then print("Initialize() Called: "..GetPrettyName()) end
		--helper.TablePrint(Controls, 1)

		Layers = {
			Video = 1,
			Audio = 2,
			Data  = 3,
			IR    = 4,
			USB   = 5
		}

    --helper.TablePrint(Properties, 1)
		if(Properties['Output Count'].Value > 0 and Properties['Input Count'].Value > 0) then
			for o = 0, Properties['Output Count'].Value do
				for i = 1, Properties['Input Count'].Value do
          -- Crosspoint EventHandlers
					Controls["vid-input_" .. i .. "-output_" .. o].EventHandler = function(ctl) 
		        if DebugFunction then print("vid-input_" .. i .. "-output_" .. o .. " pressed") end
						SetRoute(Layers.Video, o, i, ctl.Value)
						if(o == 0) then ctl.Value = 0 end -- let the individual output buttons track state
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
      end
		end

		Disconnected()
		Connect()
    GetDeviceInfo()
    --TestFeedbacks()
    
		Heartbeat:Start(PollRate)
	end

	-- Timer EventHandlers  --
	Heartbeat.EventHandler = function()
		if DebugFunction then print("Heartbeat Event Handler Called - CommandQueue size: "..#CommandQueue) end
    if #CommandQueue < 1 then
      for i = 1, Properties['Input Count'].Value do
        Query({ Command=Request["SignalPresent"].Command, Data='1,'..tostring(i) })
        Query({ Command=Request["AudioSignalPresent"].Command, Data='1,'..tostring(i) })
      end
    end
  end

	SetupDebugPrint()
	Initialize()