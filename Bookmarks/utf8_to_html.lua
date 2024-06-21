
return function (input)
  if type(input) ~= "string" then error("Expected string, got " .. type(input),2) end
  local output = {}
  local i = 0
  while i < string.len(input) do
    i = i + 1
    local c = string.byte(input,i)
    if c & 0x80 == 0 then 
      table.insert(output,string.char(c))
    else
      i = i + 1
      local c2 = string.byte(input,i)
      if c2 == nil then error("Invalid UTF8 string", 2) end
      if c2 & 0xC0 ~= 0x80 then error("Invalid UTF8 string", 2) end

      if c & 0xE0 == 0xC0 then
        local v = (c2 & 0x7F) + ((c & 0x1F) << 6)
        print(v)
        table.insert(output, "&#" .. v .. ";")
      else
        i = i + 1
        local c3 = string.byte(input,i)
        if c3 == nil then error("Invalid UTF8 string", 2) end
        if c3 & 0xC0 ~= 0x80 then error("Invalid UTF8 string", 2) end

        if c & 0xF0 == 0xE0 then
          local v = (c3 & 0x7F) + ((c2 & 0x7F)<<6) + ((c & 0x0F)<<12)
          table.insert(output, "&#" .. v .. ";")
        else
          i = i + 1
          local c4 = string.byte(input,i)
          if c4 == nil then error("Invalid UTF8 string", 2) end
          if c4 & 0xC0 ~= 0x80 then error("Invalid UTF8 string", 2) end

          if c & 0xF8 == 0xF0 then
            local v = (c4 & 0x7F) + ((c3 & 0x7F)<<6) + ((c2 & 0x7F)<<12) + ((c & 0x07)<<18)
            table.insert(output, "&#" .. v .. ";")
          else
            error("Invalid UTF8 string", 2)
          end
        end
      end
    end
  end
  return table.concat(output)
end
