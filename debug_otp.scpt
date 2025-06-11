#!/usr/bin/osascript

# Debug version of OTP script to see what messages we're finding
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
        
        # If no timestamp provided, use current time minus 300 seconds (5 minutes) for debugging
        if promptTimestamp = 0 then
            set promptTimestamp to (do shell script "date +%s") as integer
            set promptTimestamp to promptTimestamp - 300
        end if
        
        log "DEBUG: Looking for messages after timestamp: " & promptTimestamp
        
        # Try database method first with more verbose output
        set dbQuery to "sqlite3 ~/Library/Messages/chat.db \"SELECT text, datetime(date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch') as msg_time FROM message WHERE datetime(date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch') > datetime(" & promptTimestamp & ", 'unixepoch') ORDER BY date DESC LIMIT 10;\" 2>/dev/null"
        
        try
            set allRecentMessages to do shell script dbQuery
            log "DEBUG: Recent messages from database:"
            log allRecentMessages
            
            # Now look specifically for OTP patterns
            set otpQuery to "sqlite3 ~/Library/Messages/chat.db \"SELECT text FROM message WHERE (text LIKE '%VPN%' OR text LIKE '%OTP%' OR text LIKE '%FortiGate%' OR text LIKE '%verification%' OR text LIKE '%code%') AND datetime(date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch') > datetime(" & promptTimestamp & ", 'unixepoch') ORDER BY date DESC LIMIT 5;\" 2>/dev/null"
            
            set potentialOtpMessages to do shell script otpQuery
            log "DEBUG: Potential OTP messages:"
            log potentialOtpMessages
            
            if potentialOtpMessages is not "" then
                # Extract 6-digit code from the message
                set otpCode to do shell script "echo " & quoted form of potentialOtpMessages & " | grep -o '[0-9]\\{6\\}' | head -1 || echo ''"
                
                if otpCode is not "" then
                    log "DEBUG: Found OTP code: " & otpCode
                    return otpCode
                else
                    log "DEBUG: No 6-digit code found in potential messages"
                    # Try 4-8 digit codes as fallback
                    set otpCode to do shell script "echo " & quoted form of potentialOtpMessages & " | grep -o '[0-9]\\{4,8\\}' | head -1 || echo ''"
                    if otpCode is not "" then
                        log "DEBUG: Found alternate code: " & otpCode
                        return otpCode
                    end if
                end if
            else
                log "DEBUG: No potential OTP messages found"
            end if
        on error dbError
            log "DEBUG: Database query failed: " & dbError
        end try
        
        log "DEBUG: Falling back to AppleScript Messages method"
        
        # Fallback to AppleScript method
        tell application "Messages"
            set allChats to chats
            log "DEBUG: Found " & (count of allChats) & " chats"
            
            repeat with currentChat in allChats
                try
                    set chatMessages to text messages of currentChat
                    set messageCount to count of chatMessages
                    
                    if messageCount > 0 then
                        log "DEBUG: Checking chat with " & messageCount & " messages"
                        
                        -- Check last 3 messages from this chat
                        repeat with j from 1 to 3
                            if j <= messageCount then
                                try
                                    set currentMessage to item (messageCount - j + 1) of chatMessages
                                    set messageText to text of currentMessage
                                    set messageDate to date received of currentMessage
                                    
                                    log "DEBUG: Message text: " & messageText
                                    log "DEBUG: Message date: " & messageDate
                                    
                                    # Check if message contains numbers (potential OTP)
                                    set hasNumbers to do shell script "echo " & quoted form of messageText & " | grep -o '[0-9]\\{4,8\\}' | head -1 || echo ''"
                                    if hasNumbers is not "" then
                                        log "DEBUG: Found message with numbers: " & messageText
                                        return hasNumbers
                                    end if
                                on error msgError
                                    log "DEBUG: Error reading message: " & msgError
                                end try
                            end if
                        end repeat
                    end if
                on error chatError
                    log "DEBUG: Error reading chat: " & chatError
                end try
            end repeat
            
            return "NO_CODE_FOUND"
        end tell
    on error errMsg
        log "DEBUG: Script error: " & errMsg
        return "ERROR: " & errMsg
    end try
end run
