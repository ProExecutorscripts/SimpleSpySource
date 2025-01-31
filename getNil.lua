-- Used in script generator for getting nil instances
function getNil(name, class)
  for _, v in pairs(getnilinstances()) do
    if v.ClassName == class and v.Name == name then
      return v
    end
  end
  return nil -- Explicitly return nil if no match is found
end
