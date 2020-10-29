#\ -E none
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
app = lambda do |env|
  input = env['rack.input']
  case env["PATH_INFO"]
  when "/tmp_class"
    body = input.instance_variable_get(:@tmp).class.name
  when "/input_class"
    body = input.class.name
  else
    return [ 500, {}, [] ]
  end
  [ 200, {}, [ body ] ]
end
run app
