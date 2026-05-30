-- Google Translate TTS URL Generator
-- Generates TTS audio URLs using Google Translate's text-to-speech API

local tts = {}

-- Google Translate TTS text limit (in Unicode characters)
local MAX_CHARS = 200

--- Count UTF-8 characters and return the byte position of the Nth character
-- @param str UTF-8 encoded string
-- @param max_chars Maximum number of Unicode characters
-- @return truncated string (up to max_chars Unicode characters)
local function utf8_truncate(str, max_chars)
    local len = #str
    -- Fast path: if byte length <= max_chars, char count is guaranteed <= max_chars
    if len <= max_chars then return str end

    local char_count = 0
    local byte_pos = 1

    while byte_pos <= len and char_count < max_chars do
        local b = string.byte(str, byte_pos)
        local char_bytes
        if b < 0x80 then
            char_bytes = 1      -- ASCII
        elseif b < 0xE0 then
            char_bytes = 2      -- 2-byte UTF-8
        elseif b < 0xF0 then
            char_bytes = 3      -- 3-byte UTF-8 (Korean, Japanese, Chinese, etc.)
        else
            char_bytes = 4      -- 4-byte UTF-8 (emoji, etc.)
        end
        byte_pos = byte_pos + char_bytes
        char_count = char_count + 1
    end

    if byte_pos <= len then
        -- Truncated: return substring up to the last complete character
        return string.sub(str, 1, byte_pos - 1)
    end
    return str
end

--- Generate TTS URL with configurable lead silence
function tts.get_url(phrase, lang, silence_seconds)
    phrase = utf8_truncate(phrase, MAX_CHARS)
    
    -- silence_seconds를 받아서 앞에 무음 추가 (기본 0.8초)
    silence_seconds = silence_seconds or 0.8
    local silence_count = math.floor(silence_seconds * 28)  -- 대략 28개 공백 ≈ 1초
    
    if silence_count > 0 then
        phrase = string.rep(" ", silence_count) .. phrase
    end
    
    -- URL 인코딩
    local encoded = string.gsub(phrase, "([^%w%-%.%_%\~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    encoded = string.gsub(encoded, " ", "+")
    
    lang = lang or "ko"
    return "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=" .. lang .. "&q=" .. encoded
end

return tts
