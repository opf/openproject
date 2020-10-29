begin
require 'rails/railtie'
rescue LoadError
else
require 'global_id'
require 'active_support'
require 'active_support/core_ext/string/inflections'

class GlobalID
  # = GlobalID Railtie
  # Set up the signed GlobalID verifier and include Active Record support.
  class Railtie < Rails::Railtie # :nodoc:
    config.global_id = ActiveSupport::OrderedOptions.new
    config.eager_load_namespaces << GlobalID

    initializer 'global_id' do |app|
      default_expires_in = 1.month
      default_app_name = app.railtie_name.remove('_application').dasherize

      GlobalID.app = app.config.global_id.app ||= default_app_name
      SignedGlobalID.expires_in = app.config.global_id.expires_in ||= default_expires_in

      config.after_initialize do
        GlobalID.app = app.config.global_id.app ||= default_app_name
        SignedGlobalID.expires_in = app.config.global_id.expires_in ||= default_expires_in

        app.config.global_id.verifier ||= begin
          GlobalID::Verifier.new(app.key_generator.generate_key('signed_global_ids'))
        rescue ArgumentError
          nil
        end
        SignedGlobalID.verifier = app.config.global_id.verifier
      end

      ActiveSupport.on_load(:active_record) do
        require 'global_id/identification'
        send :include, GlobalID::Identification
      end
    end
  end
end

end
