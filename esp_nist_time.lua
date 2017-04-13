-- connects to a NIST Daytime server to get the current date and time
--based on http://www.esp8266.com/viewtopic.php?f=19&t=8916, first method

max_atmpt=5                 -- How many attempts to make to get time.
max_sec_wait_per_attempt=5  --How many secods to give in each attempt
checks_per_sec=2            --Number of Checks to be done per second for the data.
timer_id=2                  --timerid to use for the time keeping

TZ=-5                       -- my time zone is Eastern Standard Time
year=0                      -- global year
month=0                     -- global month
day=0                       -- global day
hour=0                      -- global hour
minute=0                    -- global minute
second=0                    -- global second
datetime=" "                 --Global Date time
datetime=nil
cur_atmpt=0                 -- Current Attempt number
cur_sec=0                   --Current second into attempt
--This will make max_attempt*max_wait_per_attempt*1/checks_per_sec numbers of loops

function getDayTime()
   local tt=0
   local conn=net.createConnection(net.TCP,0)
   conn:connect(13,"time.nist.gov")
   -- on connection event handler
   conn:on("connection",
      function(conn, payload)
         print("Connected...")
      end -- function
   ) -- end of on "connecttion" event handler
         
   -- on receive event handler         
   conn:on("receive",
      function(conn,payload)
        print("Received")
        print(payload)
        --1234567890123456789012345678901234567890123456789
        -- JJJJJ YR-MO-DA HH:MM:SS TT L H msADV UTC(NIST) *
        if string.sub(payload,39,47)=="UTC(NIST)" then
           year=tonumber(string.sub(payload,8,9))+2000
           month=tonumber(string.sub(payload,11,12))
           day=tonumber(string.sub(payload,14,15))
           hour=tonumber(string.sub(payload,17,18))
           minute=tonumber(string.sub(payload,20,21))
           second=tonumber(string.sub(payload,23,24))
           tt=tonumber(string.sub(payload,26,27))
           hour=hour+TZ    -- convert from UTC to local time
           if ((tt>1) and (tt<51)) or ((tt==51) and (hour>1)) or ((tt==1) and (hour<2)) then
              hour=hour+1  -- daylight savings time currently in effect, add one hour
           end
           hour=hour%24
        end -- if string.sub(payload,39,47)=="UTC(NIST)" then
        datetime=string.format("%02d:%02d:%02d  %02d/%02d/%04d",hour,minute,second,month,day,year)
        print("Got time = "..datetime)
      end -- function
   ) -- end of on "receive" event handler
   -- on disconnect event handler           
   conn:on("disconnection",
      function(conn,payload)
         print("Disconnected...")
         conn=nil
         payload=nil
      end -- function
   )  -- end of on "disconnecttion" event handler
end -- function getDayTime()

-- Execution starts here...
print("\ncontacting NIST server...")
cur_atmpt=1
cur_sec=0
getDayTime() -- contact the NIST daytime server for the current time and date

tmr.alarm(timer_id,1000/checks_per_sec,1,
   function()
     print(cur_sec)
     cur_sec=cur_sec + 1000/checks_per_sec
     if datetime == nil then
         print("Unable to get time and date from the NIST server. Will Retry. Attempt =" ..cur_atmpt .." Seconds in current attempt="..cur_sec/1000 )
         if cur_sec/1000 >=max_sec_wait_per_attempt then
            print("Loop Finish sec")
            if cur_atmpt>max_atmpt then
                print("Loop Finish attempt")
                cur_atmpt=nil
                cur_sec=nil
            else
                cur_atmpt=cur_atmpt+1        
                getDayTime()
                cur_sec=1000/checks_per_sec
            end
         else
            print("Loop continue sec"..cur_sec)
         end        
     else
        print("Stopping timer")
        tmr.stop(timer_id)
        print("datetime="..datetime)        
     end
   end
)
