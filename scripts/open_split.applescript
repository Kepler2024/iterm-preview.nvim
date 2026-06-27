-- open_split.applescript
--
-- Args:
--   1: target URL                  (required, e.g. http://localhost:8089/page/...)
--   2: split direction             (right|left|below|above)
--   3: iTerm profile name          (must exist; "" -> "Browser")
--   4: bridge HTML path            (absolute path; written before split)
--   5: iTerm app name              ("" -> "iTerm")
--
-- How the URL actually lands in the new pane:
--   We write a meta-refresh HTML to <bridge HTML path> that redirects to the
--   target URL. The user's iTerm Browser profile must have its Custom URL set
--   to file://<bridge HTML path>. When we split with that profile, the new
--   browser session loads its home URL, which redirects to the live preview.
--
--   (iTerm's AppleScript dictionary does not currently expose direct URL
--   navigation on browser sessions, so the bridge HTML is the load-bearing
--   mechanism rather than a fallback.)

on run argv
    set targetURL to item 1 of argv
    set splitDir to item 2 of argv
    set profileName to item 3 of argv
    set bridgeFile to item 4 of argv
    set itermApp to item 5 of argv

    if itermApp = "" then set itermApp to "iTerm"
    if profileName = "" then set profileName to "Browser"

    if bridgeFile is not "" then
        set htmlContent to "<!DOCTYPE html><meta http-equiv=\"refresh\" content=\"0; url=" & targetURL & "\">"
        do shell script "printf '%s' " & quoted form of htmlContent & " > " & quoted form of bridgeFile
    end if

    set newSessionID to ""
    using terms from application "iTerm"
        tell application itermApp
            activate
            if (count of windows) = 0 then
                create window with default profile
            end if

            tell current window
                tell current session
                    if splitDir is "below" or splitDir is "above" then
                        set newSession to (split horizontally with profile profileName)
                    else
                        set newSession to (split vertically with profile profileName)
                    end if
                end tell

                set newSessionID to (id of newSession) as text
            end tell
        end tell
    end using terms from

    return newSessionID
end run
