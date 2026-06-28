-- Single active preview. session_id is the iTerm session of the preview pane;
-- bufnr is the markdown buffer it was opened for, so auto-close can match the
-- exact buffer instead of firing on any markdown buffer.
local M = {
  session_id = nil,
  last_url = nil,
  bufnr = nil,
}

function M.set(session_id, url, bufnr)
  M.session_id = session_id
  M.last_url = url
  M.bufnr = bufnr
end

function M.clear()
  M.session_id = nil
  M.last_url = nil
  M.bufnr = nil
end

function M.has_session() return type(M.session_id) == "string" and M.session_id ~= "" end

return M
