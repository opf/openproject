# You will paginate!
module WillPaginate
end

if defined?(Rails::Railtie)
  require 'will_paginate/railtie'
elsif defined?(Rails::Initializer)
  raise "will_paginate 3.0 is not compatible with Rails 2.3 or older"
end

if defined?(Merb::AbstractController)
  require 'will_paginate/view_helpers/merb'

  Merb::BootLoader.before_app_loads do
    adapters = { :datamapper => 'data_mapper', :activerecord => 'active_record', :sequel => 'sequel' }
    # auto-load the right ORM adapter
    if adapter = adapters[Merb.orm]
      require "will_paginate/#{adapter}"
    end
  end
end

if defined?(Sinatra) and Sinatra.respond_to? :register
  require 'will_paginate/view_helpers/sinatra'
end
