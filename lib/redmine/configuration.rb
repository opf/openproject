#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module Configuration

    # Configuration default values
    @defaults = {
      'email_delivery' => nil,
      # Autologin cookie defaults:
      'autologin_cookie_name'   => 'autologin',
      'autologin_cookie_path'   => '/',
      'autologin_cookie_secure' => false,
    }

    @config = nil

    class << self
      # Loads the Redmine configuration file
      # Valid options:
      # * <tt>:file</tt>: the configuration file to load (default: config/configuration.yml)
      # * <tt>:env</tt>: the environment to load the configuration for (default: Rails.env)
      def load(options={})
        filename = options[:file] || File.join(Rails.root, 'config', 'configuration.yml')
        env = options[:env] || Rails.env

        @config = @defaults.dup

        load_deprecated_email_configuration(env)
        if File.file?(filename)
          @config.merge!(load_from_yaml(filename, env))
        end

        # Compatibility mode for those who copy email.yml over configuration.yml
        %w(delivery_method smtp_settings sendmail_settings).each do |key|
          if value = @config.delete(key)
            @config['email_delivery'] ||= {}
            @config['email_delivery'][key] = value
          end
        end

        if @config['email_delivery']
          ActionMailer::Base.perform_deliveries = true
          @config['email_delivery'].each do |k, v|
            v.symbolize_keys! if v.respond_to?(:symbolize_keys!)
            ActionMailer::Base.send("#{k}=", v)
          end
        end

        @config
      end

      # Returns a configuration setting
      def [](name)
        load unless @config
        @config[name]
      end

      # Yields a block with the specified hash configuration settings
      def with(settings)
        settings.stringify_keys!
        load unless @config
        was = settings.keys.inject({}) {|h,v| h[v] = @config[v]; h}
        @config.merge! settings
        yield if block_given?
        @config.merge! was
      end

      private

      def load_from_yaml(filename, env)
        yaml = YAML::load_file(filename)
        conf = {}
        if yaml.is_a?(Hash)
          if yaml['default']
            conf.merge!(yaml['default'])
          end
          if yaml[env]
            conf.merge!(yaml[env])
          end
        else
          $stderr.puts "#{filename} is not a valid Redmine configuration file"
          exit 1
        end
        conf
      end

      def load_deprecated_email_configuration(env)
        deprecated_email_conf = File.join(Rails.root, 'config', 'email.yml')
        if File.file?(deprecated_email_conf)
          warn "Storing outgoing emails configuration in config/email.yml is deprecated. You should now store it in config/configuration.yml using the email_delivery setting."
          @config.merge!({'email_delivery' => load_from_yaml(deprecated_email_conf, env)})
        end
      end
    end
  end
end
