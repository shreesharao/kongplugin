local M = {}

function M.should_allow_url(allowed_urls)
    if (allowed_urls) then
        for _, url in ipairs(allowed_urls) do
            if (string.find(ngx.var.uri, url)) then
                return true
            end
        end
    end
    return false
end

return M
