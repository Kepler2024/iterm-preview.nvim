local M = {
  session_id = nil,
  last_url = nil,
}

function M.set(session_id, url)
  M.session_id = session_id
  M.last_url = url
end

function M.clear()
  M.session_id = nil
  M.last_url = nil
end

function M.has_session()
  return type(M.session_id) == "string" and M.session_id ~= ""
end

return M
