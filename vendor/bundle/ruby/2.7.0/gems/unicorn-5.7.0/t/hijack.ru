use Rack::Lint
use Rack::ContentLength
use Rack::ContentType, "text/plain"
class DieIfUsed
  @@n = 0
  def each
    abort "body.each called after response hijack\n"
  end

  def close
    warn "closed DieIfUsed #{@@n += 1}\n"
  end
end

envs = []

run lambda { |env|
  case env["PATH_INFO"]
  when "/hijack_req"
    if env["rack.hijack?"]
      io = env["rack.hijack"].call
      envs << env
      if io.respond_to?(:read_nonblock) &&
         env["rack.hijack_io"].respond_to?(:read_nonblock)

        # exercise both, since we Rack::Lint may use different objects
        env["rack.hijack_io"].write("HTTP/1.0 200 OK\r\n\r\n")
        io.write("request.hijacked")
        io.close
        return [ 500, {}, DieIfUsed.new ]
      end
    end
    [ 500, {}, [ "hijack BAD\n" ] ]
  when "/hijack_res"
    r = "response.hijacked"
    [ 200,
      {
        "Content-Length" => r.bytesize.to_s,
        "rack.hijack" => proc do |io|
          envs << env
          io.write(r)
          io.close
        end
      },
      DieIfUsed.new
    ]
  when "/normal_env_id"
    b = "#{env.object_id}\n"
    h = {
      'Content-Type' => 'text/plain',
      'Content-Length' => b.bytesize.to_s,
    }
    [ 200, h, [ b ] ]
  end
}
