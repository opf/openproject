# lobby_boy
Rails engine for OpenID Connect Session Management

Assumes the use of OmniAuth and the `omniauth-openid-connect` strategy.

## Dependencies

If not present yet add the following gem:

```ruby
gem 'omniauth-openid-connect', git: 'https://github.com/jjbohn/omniauth-openid-connect.git', branch: 'master'
```

## Usage

You have to do 6 steps to enable session management in your application:

1. Mount the engine.
2. Configure lobby_boy.
3. Render lobby_boy's iframes partial in your layout.
4. Call lobby_boy's `SessionHelper#confirm_login!` when the user is logged in.
5. Call lobby_boy's `SessionHelper#logout_at_op!` when the user logs out.
6. Implement the end_session_endpoint to be used by lobby_boys Javascript.

The following sections will describe those steps in more detail.

### 1. Mount the engine

To mount the engine into your application add the following to your `config/routes.rb`:

```ruby
require 'lobby_boy'

Rails.application.routes.draw do
  mount LobbyBoy::Engine, at: '/'
end
```

### 2. Configure lobby_boy

The are two sections to be configured:

*client*

This refers to your application which is an OpenID Connect client.
All lobby_boy needs to know about it is its `host` and `end_session_endpoint` (i.e. logout URL).

Here are all available client options, the rest of them which are optional:

```ruby
LobbyBoy.configure_client! host: 'https://myapp.com',
                           end_session_endpoint: '/logout',
                           # (optional) Derived from host per default:
                           cookie_domain: "myapp.com",
                           # (optional) A block executed in the context of a rails controller
                           # which returns true if the user is logged into
                           # the application:
                           logged_in: ->() { session.include? :user },
                           # (optional) Seconds before the ID token's expiration at which
                           # to re-authenticate early:
                           refresh_offset: 60,
                           # (optional) Check the session state every 30 seconds and refresh
                           # if out of sync:
                           refresh_interval: 30,
                           # (optional) A .js.erb (app/views/session/_on_login.js.erb) partial
                           # to be rendered the code of which will be executed if the user is
                           # logged in automatically:
                           on_login_js_partial: 'session/on_login',
                           # (optional) A .js.erb (app/views/session/_on_logout.js.erb) partial
                           # to be rendered the code of which will be executed if the user is
                           # logged out automatically:
                           on_logout_js_partial: 'session/on_logout'

```

*provider*

The OpenIDConnect provider has to support Session Management too. The essential details
required for the provider are its `name` (its strategy being available under `/auth/$name`)
and the `identifier` under which your client is registered at the provider.

If the provider supports discovery this is everything. If not you will also have to configure
the `issuer`, `end_session_endpoint` and `check_session_iframe`.

For instance for **Concierge** which does not support discovery yet:

```ruby
LobbyBoy.configure_provider! name:                 'concierge',
                             client_id:            'openproject',
                             issuer:               'https://concierge.openproject.com',
                             end_session_endpoint: '/session/end',
                             check_session_iframe: '/session/check']
```

### 3. Render lobby_boy's iframes partial in your layout.

Session Management requires two iframes, the relying party iframe and the OpenIDConnect provider iframe,
to be rendered at all times, on every page.
In a standard rails application you would do this by inserting the following line into
`app/views/layouts/application.html.erb`:

```
<%= render 'lobby_boy/iframes' %>
```

### 4. Call lobby_boy's `SessionHelper#confirm_login!` when the user is logged in.

The `#confirm_login!` helper stores the logged-in user's ID token in the session
and sets the `oidc_rp_state` cookie. Which means that this helper has to be called
in the context of the final action handling the user's login.

Another thing the login must do is to redirect the user to the omniauth origin.
It should do that already if implemented correctly.

For instance:

```ruby
class SessionController < ApplicationController
  include LobbyBoy::SessionHelper

  def login
    # existing logic:
    # ...

    confirm_login!
    redirect_to(request.env['omniauth.origin'] || default_url)
  end
end
```

It is important that your login action redirects to `omniauth.origin` after a
successful login.

*Optional: reauthentication*

If you have to behave differently when the user is reauthenticated you can
additionally to the changes above use the reauthentication helpers.

```ruby
class SessionController < ApplicationController
  include LobbyBoy::SessionHelper

  def login
    # existing logic:
    # ...

    confirm_login!

    if reauthentication?
      finish_reauthentication!
    else
      go_on_to_do_more_stuff_not_necessary_on_reauthentication
    end
  end
end

### Call lobby_boy's `SessionHelper#logout_at_op!` when the user logs out.

When the user logs out of the application they should also be logged out of the
OpenID Connect provider. To do that call the `#logout_at_op!` helper in your existing logout action.
The helper will redirect the user to the provider's logout endpoint to log them out globally.
You can pass a return URL to which the provider will send the user after the logout.

For instance:

```ruby
class SessionController < ApplicationController
  def logout
    # The helper will return false and do nothing the provider's
    # end_session_endpoint is not configured.
    unless logout_at_op! root_url
      redirect_to root_url
    end
  end
end
```

### 6. Implement the end_session_endpoint to be used by lobby_boys Javascript.

The Javascript of lobby_boy may logout the user when it realizes that
the user has been logged out at the OpenID Connect provider.
You have to implement the `end_session_endpoint` and after logging out
the user you have to call `finish_logout!` from LobbyBoy's `SessionHelper`.

For instance:

```ruby
class SessionController < ApplicationController
  include LobbyBoy::SessionHelper

  def lobby_boy_logout
    logout_user!
    finish_logout!
  end
end
```
