## Named Appends

Named Appends are blocks of code that can be reused and composed during requests. e.g. If a certain partial is rendered conditionally, and the csp needs to be adjusted for that partial, you can create a named append for that situation. The value returned by the block will be passed into `append_content_security_policy_directives`. The current request object is passed as an argument to the block for even more flexibility. Reusing a configuration name is not allowed and will throw an exception.

```ruby
def show
  if include_widget?
    @widget = widget.render
    use_content_security_policy_named_append(:widget_partial)
  end
end


SecureHeaders::Configuration.named_append(:widget_partial) do |request|
  SecureHeaders.override_x_frame_options(request, "DENY")
  if request.controller_instance.current_user.in_test_bucket?
    { child_src: %w(beta.thirdpartyhost.com) }
  else
    { child_src: %w(thirdpartyhost.com) }
  end
end
```

You can use as many named appends as you would like per request, but be careful because order of inclusion matters. Consider the following:

```ruby
SecureHeader::Configuration.default do |config|
  config.csp = { default_src: %w('self')}
end

SecureHeaders::Configuration.named_append(:A) do |request|
  { default_src: %w(myhost.com) }
end

SecureHeaders::Configuration.named_append(:B) do |request|
  { script_src: %w('unsafe-eval') }
end
```

The following code will produce different policies due to the way policies are normalized (e.g. providing a previously undefined directive that inherits from `default-src`, removing host source values when `*` is provided. Removing `'none'` when additional values are present, etc.):

```ruby
def index
  use_content_security_policy_named_append(:A)
  use_content_security_policy_named_append(:B)
  # produces default-src 'self' myhost.com; script-src 'self' myhost.com 'unsafe-eval';
end

def show
  use_content_security_policy_named_append(:B)
  use_content_security_policy_named_append(:A)
  # produces default-src 'self' myhost.com; script-src 'self' 'unsafe-eval';
end
```


## Named overrides

Named overrides serve two purposes:

* To be able to refer to a configuration by simple name.
* By precomputing the headers for a named configuration, the headers generated once and reused over every request.

To use a named override, drop a `SecureHeaders::Configuration.override` block **outside** of method definitions and then declare which named override you'd like to use. You can even override an override.

```ruby
class ApplicationController < ActionController::Base
  SecureHeaders::Configuration.default do |config|
    config.csp = {
      default_src: %w('self'),
      script_src: %w(example.org)
    }
  end

  # override default configuration
  SecureHeaders::Configuration.override(:script_from_otherdomain_com) do |config|
    config.csp[:script_src] << "otherdomain.com"
  end
end

class MyController < ApplicationController
  def index
    # Produces default-src 'self'; script-src example.org otherdomain.com
    use_secure_headers_override(:script_from_otherdomain_com)
  end

  def show
    # Produces default-src 'self'; script-src example.org otherdomain.org evenanotherdomain.com
    use_secure_headers_override(:another_config)
  end
end
```

Reusing a configuration name is not allowed and will throw an exception.

By default, a no-op configuration is provided. No headers will be set when this default override is used.

```ruby
class MyController < ApplicationController
  def index
    SecureHeaders.opt_out_of_all_protection(request)
  end
end
```
