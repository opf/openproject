# Be sure to restart your server when you modify this file.

# Just modifying the defaults do not work
# see:
# - https://github.com/hotwired/turbo-rails/issues/155
# - https://github.com/rails/rails/issues/41795
ActiveSupport::Reloader.to_prepare do
  ApplicationController.renderer.instance_variable_set(:@env,
                                                       ApplicationController.renderer.instance_variable_get(:@env).merge(
                                                         "HTTP_HOST" => Setting.host_name,
                                                         "HTTPS" => Setting.https?,
                                                         "SCRIPT_NAME" => OpenProject::Configuration.rails_relative_url_root
                                                       ))
end
