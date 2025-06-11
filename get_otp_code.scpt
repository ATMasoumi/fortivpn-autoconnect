#!/usr/bin/osascript

# Get OTP code from Messages app - looks for messages that arrived AFTER the given timestamp
on run argv
    try
        # Get the timestamp parameter (when 2FA prompt appeared)
        set promptTimestamp to 0
        if (count of argv) > 0 then
            try
                set promptTimestamp to (item 1 of argv) as integer
            on error
                set promptTimestamp to 0
            end try
        end if
        
        # If no timestamp provided, use current time minus 10 seconds as fallback
        if promptTimestamp = 0 then
            set promptTimestamp to (do shell script "date +%s") as integer
            set promptTimestamp to promptTimestamp - 10
        end if
        
        # Use database method to get the most recent VPN OTP message AFTER the prompt timestamp
        # Use a more optimized query that supports both English and Persian/Farsi messages
        set dbQuery to "sqlite3 ~/Library/Messages/chat.db \"SELECT text FROM message WHERE (text LIKE '%VPN FortiGate%' OR text LIKE '%OTP%' OR text LIKE '%FortiGate%' OR text LIKE '%کد OTP%' OR text LIKE '%واحد عملیات%') AND datetime(date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch') > datetime(" & promptTimestamp & ", 'unixepoch') ORDER BY date DESC LIMIT 1;\" 2>/dev/null"
        
        try
            set messageText to do shell script dbQuery
            
            if messageText is not "" then
                # Extract 6-digit code from the message (handle multi-line messages and different languages)
                set otpCode to do shell script "echo " & quoted form of messageText & " | grep -o '[0-9]\\{6\\}' | head -1 || echo ''"
                
                if otpCode is not "" then
                    return otpCode
                else
                    # Try 4-8 digit codes as fallback for different OTP formats
                    set otpCode to do shell script "echo " & quoted form of messageText & " | grep -o '[0-9]\\{4,8\\}' | head -1 || echo ''"
                    if otpCode is not "" then
                        return otpCode
                    end if
                end if
            end if
        on error
            # Database method failed, try AppleScript method as fallback
        end try
        
        # Fallback to original AppleScript method (also checking messages after prompt timestamp)
        tell application "Messages"
            set otpPattern to "VPN FortiGate"
            set fortigatePattern to "FortiGate"
            set persianOtpPattern to "کد OTP"
            set persianSenderPattern to "واحد عملیات"
            
            # Convert timestamp to AppleScript date
            set promptDate to (do shell script "date -r " & promptTimestamp) as string
            set promptDate to date promptDate
            
            -- Get all chats
            set allChats to chats
            
            repeat with currentChat in allChats
                try
                    set chatMessages to text messages of currentChat
                    set messageCount to count of chatMessages
                    
                    if messageCount > 0 then
                        -- Check last 5 messages from this chat
                        repeat with j from 1 to 5
                            if j <= messageCount then
                                try
                                    set currentMessage to item (messageCount - j + 1) of chatMessages
                                    set messageText to text of currentMessage
                                    set messageDate to date received of currentMessage
                                    
                                    -- Check if message arrived AFTER the 2FA prompt
                                    if messageDate > promptDate then
                                        -- Check if this is an OTP message (English and Persian patterns)
                                        if messageText contains otpPattern or messageText contains fortigatePattern or messageText contains persianOtpPattern or messageText contains persianSenderPattern then
                                            -- Use shell command to extract 6-digit code
                                            set sixDigitCode to do shell script "echo " & quoted form of messageText & " | grep -o '[0-9]\\{6\\}' | head -1 || echo ''"
                                            if sixDigitCode is not "" then
                                                return sixDigitCode
                                            else
                                                -- Try 4-8 digit codes as fallback
                                                set anyDigitCode to do shell script "echo " & quoted form of messageText & " | grep -o '[0-9]\\{4,8\\}' | head -1 || echo ''"
                                                if anyDigitCode is not "" then
                                                    return anyDigitCode
                                                end if
                                            end if
                                        end if
                                    end if
                                on error
                                    -- Skip messages that can't be read
                                end try
                            end if
                        end repeat
                    end if
                on error
                    -- Skip chats that can't be read
                end try
            end repeat
            
            return ""
        end tell
    on error errMsg
        return ""
    end try
end run
