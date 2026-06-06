local MAV_SEVERITY = {
    EMERGENCY = 0,
    ALERT = 1,
    CRITICAL = 2,
    ERROR = 3,
    WARNING = 4,
    NOTICE = 5,
    INFO = 6,
    DEBUG = 7
}

local MAV_SYSID = Parameter("SYSID_THISMAV")
local my_sysid = math.floor(MAV_SYSID:get())
local SEND_INTERVAL_MS = 1000
local last_send_ms = 0

local mavlink_msgs = require("MAVLink/mavlink_msgs")
local NAMED_VALUE_FLOAT_msgid = mavlink_msgs.get_msgid("NAMED_VALUE_FLOAT")
local msg_map = {}

msg_map[NAMED_VALUE_FLOAT_msgid] = "NAMED_VALUE_FLOAT"

mavlink:init(10, 1)
mavlink:register_rx_msgid(NAMED_VALUE_FLOAT_msgid)
local function sendMSG()
    local now_ms = millis():toint()
    if now_ms - last_send_ms >= SEND_INTERVAL_MS then
        last_send_ms = now_ms
        gcs:send_named_float("NVF", my_sysid)
        -- mavlink.send_chan(0, mavlink_msgs.encode("NAMED_VALUE_FLOAT", {time_boot_ms = millis():toint(), name = "NVF", value = my_sysid}))
    end
end

local function recvMSG()
    while true do
        local msg,_,timestamp_ms = mavlink.receive_chan()
        if not msg then
            gcs:send_text(MAV_SEVERITY.INFO, string.format("no message"))
            return
        end
        local parsed_msg = mavlink_msgs.decode(msg, msg_map)
        if (parsed_msg ~= nil) and (parsed_msg.msgid == NAMED_VALUE_FLOAT_msgid) then
            local value = parsed_msg.value
            gcs:send_text(
                MAV_SEVERITY.INFO,
                string.format("remote = %u self = %u", value, my_sysid)
            )
        end
    end
end

local function update()
    sendMSG()
    recvMSG()
    return update, 1000
end

gcs:send_text(MAV_SEVERITY.INFO, "Loaded named_value_float_bridge.lua")
return update, 1000