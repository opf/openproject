run(lambda { |env|
  body = "#{caller.size}\n"
  h = {
    "Content-Length" => body.size.to_s,
    "Content-Type" => "text/plain",
  }
  [ 200, h, [ body ] ]
})
