--debugPrint("package path:"..package.path)
--package.path = "/mnt/sdcard/BlowTorch/?.lua"

require("serialize")
--make a button.
--Note("in the chat server")

--NewTrigger("test","pattern",{enabled=true,once=true,regex=true},{type="gag",fire="always"},{type="replace",text="fsdfs",fire="never"})
--NewTrigger("test2","pattern2",{enabled=false,once=false,regex=false},{type="notification",title="foo",message="bar"},{type="toast",message="toasty",duration=1},{type="send",text="foo",fire="windowClosed"},{type="replace",text="haha",fire="windowOpen"},{type="gag",output=false,log=false,retarget="chats"},{type="color",foreground=212,background=40,fire="never"})

--DeleteTrigger("test")
--DeleteTrigger("test2")

local current_version = 14

chatWindow = GetWindowTokenByName("chats")
AppendWindowSettings("chats")
chatWindowName = "chats"

currentChannel = "main"
buffers = {}
buffers[currentChannel] = chatWindow:getBuffer()

--altbuffer = luajava.newInstance("com.offsetnull.bt.window.TextTree");
--altbuffer:addString("i am the alternate buffer, rock on.")

--foobuffer = luajava.newInstance("com.offsetnull.bt.window.TextTree");
--foobuffer:addString("this is the foo buffer, buffffererere.")

--buffers["alt"] = altbuffer;
--buffers["filler"] = foobuffer;
--buffers["lots"] = foobuffer;
--buffers["and"] = foobuffer;
--buffers["lots"] = foobuffer;
--buffers["more"] = foobuffer;
--buffers["channels"] = foobuffer;
--buffers[""] = foobuffer;
--buffers["channels"] = foobuffer;




function updateSelection(newChannel)

	if(newChannel == currentChannel) then
		return
	end
	
	--update currenChannel to newChannel
	currentChannel = newChannel
	--get the appropriate channel buffer from the buffers table.
	buffer = buffers[currentChannel]
	--update the chat window (hypothetically, through
	chatWindow:setBuffer(buffer)
	
	InvalidateWindowText(chatWindowName)

end

--local tmpmap = {}
function updateUIButtons()
	local tmpmap = {}
	for i,b in pairs(buffers) do
		tmpmap[i] = "foo"
		--table.insert(tmp,i)
		
	end
	
	--local selected = currentChannel
	
	local a = {}
	a.list = tmpmap
	a.selected = currentChannel
	
	WindowXCallS(chatWindowName,"loadButtons",serialize(a))
end

firstLoad = true

function initReady(arg)
	--arg is meaningless here.
	updateUIButtons()
	if(firstLoad) then
		firstLoad = false
		EchoText(string.format("Chat Plugin v1.%d Loaded...\n\n",current_version))
	end
	
end



function processChat(name,line,replaceMap)
	
	--get chat channel from replacementMap
	channel = replaceMap["1"]
	
	if(currentChannel == "main") then
		AppendLineToWindow(chatWindowName,line)
		if option_add_extra then AppendLineToWindow(chatWindowName,"\n") end
	else
		mainBuffer = buffers["main"]
		mainBuffer:appendLine(line)
		if option_add_extra then mainBuffer:addString("\n") end
	end

	--if appropriate channel already has a sub buffer.
	if(channel ~= nil) then
		--append this line to it
		
		if(currentChannel == channel) then
			AppendLineToWindow(chatWindowName,line)
			if option_add_extra then AppendLineToWindow(chatWindowName,"\n") end
		else
			channelBuffer = buffers[channel]
			if(channelBuffer == nil) then
				channelBuffer = luajava.newInstance("com.offsetnull.bt.window.TextTree")
				--channelBuffer:appendLine(line)
				buffers[channel] = channelBuffer
				updateUIButtons()
			end
			channelBuffer:appendLine(line)
			if option_add_extra then channelBuffer:addString("\n") end
		end
	else
		--create a new buffer
		newchannel = luajava.newInstance("com.offsetnull.bt.window.TextTree")
		--attatch a copy of this line to the new buffer
		newchannel:appendLine(line)
		if option_add_extra then newchannel:addString("\n") end
		--keep track of new buffer in buffer map, under the name of the matched channel.
		buffers[channel] = newchannel
		updateUIButtons()
	end
	
	if option_gag_extra then
		EnableTrigger("grabber",true)
	end

	--append this line to the main buffer, this always happens.
	--mainBuffer = buffers["main"]
	
end

function processGrab()
	EnableTrigger("grabber",false)
end

function OnOptionChanged(key,value)
	--Note("\n chatwindow in on option changed, key:"..key.."\n")
	local func = optionsTable[key]
	if(func ~= nil) then
		func(value)
	end
end

function finishUpdate()
	--Note("\nStarting finishupdate\n")
	--get the window settings:
	local wsettings = chatWindow:getSettings()
	local psettings = GetPluginSettings()
	
	--backup settings keys to sharedprefs
	prefs = context:getSharedPreferences(string.format("chat_window_%d",GetPluginID()),0)
	
	ed = prefs:edit()
	local op = psettings:findOptionByKey("height")
	local opval = op:getValue()
	
	ed:putString("height",tostring(opval))
	
	ed:commit()
	--Note("\nReloading settings\n")
	ReloadSettings()
	--reboot
end

function OnBackgroundStartup()
	--Note("\nbackground startup started\n")
	--if(PluginSupports("button_window","testxcall")) then
	
	--	CallPlugin("button_window","testxcall","datataa")
	--else
	--	Note("Button window plugin does not support testxcall")
	--end
	
	local psettings = GetPluginSettings()
	
	--backup settings keys to sharedprefs
	local prefs = context:getSharedPreferences(string.format("chat_window_%d",GetPluginID()),0)
	if(prefs:contains("height")) then
		local val = prefs:getString("height","77")
		--Note("\nContains height key "..tostring(val).."\n")
		
		psettings:findOptionByKey("height"):setValue(val)
		local ed = prefs:edit()
		ed:clear()
		ed:commit()
		setWindowSize(val)
	else
		--Note("\nchat window update prefs not found\n")
	end
	
	
end

function recvxcall(data)
	Note("chat window recieved data:"..data)
end

function setWindowSize(size)
	--Note("\nin setWindowSize()"..size.."\n")
	local layouts = chatWindow:getLayouts()
	local keys = layouts:keySet()
	local iterator = keys:iterator()
	while(iterator:hasNext()) do
		local key = iterator:next()
		local layoutGroup = layouts:get(key)
		layoutGroup:setPortraitHeight(tonumber(size))
		layoutGroup:setLandscapeHeight(tonumber(size))
	end
	if(UserPresent()) then
		WindowXCallS(chatWindowName,"setWindowSize",tostring(size))
	end
end

function setExtraGag(val)
	if(val == "true") then
		option_gag_extra = true
	else
		option_gag_extra = false
	end
end

function setExtraAdd(val)
	if(val == "true") then
		option_add_extra = true
	else
		option_add_extra = false
	end
end

optionsTable = {}
optionsTable.height = setWindowSize
optionsTable.gag_extra = setExtraGag
optionsTable.add_extra = setExtraAdd

RegisterSpecialCommand("http","testHttp")

function testHttp()
	WindowXCallS(chatWindowName,"runDatRunner","FOO")
end

function startUpdate()
	--Note("\ntesting\n")
	WindowXCallS(chatWindowName,"runDatRunner","FOO")
end

function EchoText(text)
	AppendLineToWindow(chatWindowName,text)
end

function FakeChan(text)
		newchannel = luajava.newInstance("com.offsetnull.bt.window.TextTree")
		--attatch a copy of this line to the new buffer
		--newchannel:appendLine(line)
		--keep track of new buffer in buffer map, under the name of the matched channel.
		buffers[text] = newchannel
		updateUIButtons()
end





