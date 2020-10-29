#\-N --debug
run(lambda do |env|
  case env['PATH_INFO']
  when '/vars'
    b = "debug=#{$DEBUG.inspect}\n" \
        "lint=#{caller.grep(%r{rack/lint\.rb})[0].split(':')[0]}\n"
  end
  h = {
    'Content-Length' => b.size.to_s,
    'Content-Type' => 'text/plain',
  }
  [ 200, h, [ b ] ]
end)
