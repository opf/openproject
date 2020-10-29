use Rack::ContentType, "text/plain"
fifo_path = ENV["TEST_FIFO"] or abort "TEST_FIFO not set"
run lambda { |env|
  pid = fork do
    File.open(fifo_path, "wb") do |fp|
      fp.write "HIHI"
    end
  end
  Process.detach(pid)
  [ 200, {}, [ pid.to_s ] ]
}
