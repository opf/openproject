## Sinatra

Here's an example using SecureHeaders for Sinatra applications:

```ruby
require 'rubygems'
require 'sinatra'
require 'haml'
require 'secure_headers'

use SecureHeaders::Middleware

SecureHeaders::Configuration.default do |config|
  ...
end

class Donkey < Sinatra::Application
  set :root, APP_ROOT

  get '/' do
    SecureHeaders.override_x_frame_options(request, SecureHeaders::OPT_OUT)
    haml :index
  end
end
```
