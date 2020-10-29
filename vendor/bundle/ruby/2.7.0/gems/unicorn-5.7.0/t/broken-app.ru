# we do not want Rack::Lint or anything to protect us
use Rack::ContentLength
use Rack::ContentType, "text/plain"
map "/" do
  run lambda { |env| [ 200, {}, [ "OK\n" ] ] }
end
map "/raise" do
  run lambda { |env| raise "BAD" }
end
map "/nil" do
  run lambda { |env| nil }
end
