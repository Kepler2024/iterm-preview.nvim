-- close_split.applescript
--
-- Args:
--   1: target session id   (required)
--   2: iTerm app name      ("" -> "iTerm")
--
-- Iterates all windows/tabs/sessions and closes the session whose id matches.

on run argv
    set targetID to item 1 of argv
    set itermApp to item 2 of argv
    if itermApp = "" then set itermApp to "iTerm"

    using terms from application "iTerm"
        tell application itermApp
            repeat with w in windows
                repeat with t in tabs of w
                    repeat with s in sessions of t
                        if (id of s as text) is targetID then
                            tell s to close
                            return "closed"
                        end if
                    end repeat
                end repeat
            end repeat
        end tell
    end using terms from
    return "not_found"
end run
