obs = obslua

-- Global variables to hold settings
n8n_form_url = "http://localhost:5678/form/YOUR-FORM-ID"
open_browser = true

function script_description()
    return "Automatically opens the n8n Form page in your browser when OBS finishes recording, pre-filling the video path and filename so you can enter the title and description for YouTube upload.\n\n" ..
           "Configuration:\n" ..
           "1. Paste your n8n Form Production URL below.\n" ..
           "2. Toggle 'Open Browser on Stop' on."
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "n8n_form_url", "n8n Form URL", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_bool(props, "open_browser", "Open Browser on Stop")
    return props
end

function script_update(settings)
    n8n_form_url = obs.obs_data_get_string(settings, "n8n_form_url")
    open_browser = obs.obs_data_get_bool(settings, "open_browser")
end

-- Helper: Get filename from path
function get_filename(path)
    return path:match("^.+\\([^\\]+)$") or path:match("^.+/(.+)$") or path
end

-- Helper: Get filename without extension
function get_filename_without_ext(path)
    local filename = get_filename(path)
    return filename:match("(.+)%.%w+$") or filename
end

-- Helper: URL Encode string
function url_encode(str)
   if str then
      str = str:gsub("\n", "\r\n")
      str = str:gsub("([^%w %-%_%.%~])", function (c)
         return string.format("%%%02X", string.byte(c))
      end)
      str = str:gsub(" ", "+")
   end
   return str
end

-- Event handler
function on_event(event)
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
        -- Retrieve path of the last recording
        local path = obs.obs_frontend_get_last_recording()
        
        if path ~= nil and path ~= "" then
            print("[n8n-obs2yt] Recording stopped. File path: " .. path)
            
            if open_browser then
                local filename = get_filename_without_ext(path)
                local encoded_path = url_encode(path)
                local encoded_title = url_encode(filename)
                
                -- Build URL with query parameters
                -- Fields in n8n Form Trigger will map to:
                -- 'video_path' -> path of the file
                -- 'title' -> default filename
                local url = n8n_form_url
                if url:find("%?") then
                    url = url .. "&video_path=" .. encoded_path .. "&title=" .. encoded_title
                else
                    url = url .. "?video_path=" .. encoded_path .. "&title=" .. encoded_title
                end
                
                print("[n8n-obs2yt] Opening browser: " .. url)
                
                -- Open the default browser on Windows
                local cmd = 'start "" "' .. url .. '"'
                os.execute(cmd)
            end
        else
            print("[n8n-obs2yt] Recording stopped, but no file path was retrieved.")
        end
    end
end

function script_load(settings)
    obs.obs_frontend_add_event_callback(on_event)
    print("[n8n-obs2yt] Lua script loaded successfully.")
end
