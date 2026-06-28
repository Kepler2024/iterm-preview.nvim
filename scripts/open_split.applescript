-- open_split.applescript
--
-- Args:
--   1: split direction    (right|left|below|above)
--   2: iTerm profile name  (must exist; "" -> "Browser")
--   3: iTerm app name      ("" -> "iTerm")
--
-- The target URL is NOT passed here. Lua writes a meta-refresh bridge file and
-- the chosen iTerm Browser profile loads it via its Custom URL (file://...),
-- which redirects the new pane to the live preview. This script only performs
-- the split and returns the new session id.
--
-- After splitting, focus is returned to the originally-active session so the
-- editor keeps the keyboard, the whole point of previewing in-terminal.
--
-- `using terms from application "iTerm"` is load-bearing: AppleScript only
-- loads an app's scripting dictionary at compile time when the app name is a
-- string literal. Because `itermApp` is a runtime variable, iTerm verbs
-- (split vertically, with profile, create window) would otherwise fail with
-- error -2741. Do not remove it.

on run argv
    set splitDir to item 1 of argv
    set profileName to item 2 of argv
    set itermApp to item 3 of argv

    if itermApp = "" then set itermApp to "iTerm"
    if profileName = "" then set profileName to "Browser"

    set newSessionID to ""
    using terms from application "iTerm"
        tell application itermApp
            activate
            if (count of windows) = 0 then
                create window with default profile
            end if

            tell current window
                set prevSession to current session
                tell current session
                    if splitDir is "below" or splitDir is "above" then
                        set newSession to (split horizontally with profile profileName)
                    else
                        set newSession to (split vertically with profile profileName)
                    end if
                end tell

                set newSessionID to (id of newSession) as text
                tell prevSession to select
            end tell
        end tell
    end using terms from

    return newSessionID
end run
