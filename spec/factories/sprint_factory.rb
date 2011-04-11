Factory.define(:sprint) do |s|
  s.name "version"
  s.effective_date Date.today + 14.days
  s.sharing "none"
  s.status "open"
end