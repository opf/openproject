module Stringex
  module ActsAsUrl
    module Adapter
      class Base
        attr_accessor :base_url, :callback_options, :configuration, :instance, :klass, :settings

        def initialize(configuration)
          ensure_loadable
          self.configuration = configuration
          self.settings = configuration.settings
        end

        def create_callbacks!(klass)
          self.klass = klass
          self.callback_options = {}
          create_method_to_callback
          create_callback
        end

        def ensure_unique_url!(instance)
          @url_owners = nil
          self.instance = instance

          handle_url!
          handle_blacklisted_url!
          handle_duplicate_url! unless settings.allow_duplicates
        end

        def initialize_urls!(klass)
          self.klass = klass
          klass_previous_instances do |instance|
            ensure_unique_url_for! instance
          end
        end

        def url_attribute(instance)
          # Retrieve from database record if there are errors on attribute_to_urlify
          if !is_new?(instance) && is_present?(instance.errors[settings.attribute_to_urlify])
            self.instance = instance
            read_attribute instance_from_db, settings.url_attribute
          else
            read_attribute instance, settings.url_attribute
          end
        end

        def self.ensure_loadable
          raise "The #{self} adapter cannot be loaded" unless loadable?
          Stringex::ActsAsUrl::Adapter.add_loaded_adapter self
        end

        def self.loadable?
          orm_class
        rescue NameError
          false
        end

      private

        def add_new_record_url_owner_conditions
          return if is_new?(instance)
          @url_owner_conditions.first << " and #{primary_key} != ?"
          @url_owner_conditions << instance.id
        end

        def add_scoped_url_owner_conditions
          [settings.scope_for_url].flatten.compact.each do |scope|
            @url_owner_conditions.first << " and #{scope} = ?"
            @url_owner_conditions << instance.send(scope)
          end
        end

        def create_callback
          klass.send klass_callback_method, :ensure_unique_url, callback_options
        end

        def klass_callback_method
          settings.sync_url ? klass_sync_url_callback_method : klass_non_sync_url_callback_method
        end

        def klass_sync_url_callback_method
          configuration.settings.callback_method
        end

        def klass_non_sync_url_callback_method
          case configuration.settings.callback_method
          when :before_save
            :before_create
          else # :before_validation
            callback_options[:on] = :create
            configuration.settings.callback_method
          end
        end

        def create_method_to_callback
          klass.class_eval <<-"END"
            def #{settings.url_attribute}
              acts_as_url_configuration.adapter.url_attribute self
            end
          END
        end

        def duplicate_for_base_url(n)
          "#{base_url}#{settings.duplicate_count_separator}#{n}"
        end

        def ensure_loadable
          self.class.ensure_loadable
        end

        # NOTE: The <tt>instance</tt> here is not the cached instance but a block variable
        # passed from <tt>klass_previous_instances</tt>, just to be clear
        def ensure_unique_url_for!(instance)
          instance.send :ensure_unique_url
          instance.save
        end

        def get_base_url_owner_conditions
          @url_owner_conditions = ["#{settings.url_attribute} LIKE ?", base_url + '%']
        end

        def handle_duplicate_url!
          return if !url_taken?(base_url)
          n = nil
          sequence = duplicate_url_sequence.tap(&:rewind)
          loop do
            n = sequence.next
            break unless url_taken?(duplicate_for_base_url(n))
          end
          write_url_attribute duplicate_for_base_url(n)
        end

        def duplicate_url_sequence
          settings.duplicate_sequence ||
            Enumerator.new do |enum|
              n = 1
              loop do
                enum.yield n
                n += 1
              end
            end
        end

        def url_taken?(url)
          if settings.url_taken_method
            instance.send(settings.url_taken_method, url)
          else
            url_owners.any?{|owner| url_attribute_for(owner) == url}
          end
        end

        def handle_url!
          self.base_url = instance.send(settings.url_attribute)
          modify_base_url if is_blank?(base_url) || !settings.only_when_blank
          write_url_attribute base_url
        end

        def handle_blacklisted_url!
          return unless settings.blacklist.to_set.include?(base_url)
          self.base_url = settings.blacklist_policy.call(instance, base_url)
          write_url_attribute base_url
        end

        def instance_from_db
          instance.class.find(instance.id)
        end

        def is_blank?(object)
          object.blank?
        end

        def is_new?(object)
          object.new_record?
        end

        def is_present?(object)
          object.present?
        end

        def loadable?
          self.class.loadable?
        end

        def modify_base_url
          root = instance.send(settings.attribute_to_urlify).to_s
          self.base_url = root.to_url(configuration.string_extensions_settings)
        end

        def orm_class
          self.class.orm_class
        end

        def primary_key
          instance.class.primary_key
        end

        def read_attribute(instance, attribute)
          instance.read_attribute attribute
        end

        def url_attribute_for(object)
          object.send settings.url_attribute
        end

        def url_owner_conditions
          get_base_url_owner_conditions
          add_new_record_url_owner_conditions
          add_scoped_url_owner_conditions

          @url_owner_conditions
        end

        def url_owners
          @url_owners ||= url_owners_class.unscoped.where(url_owner_conditions).to_a
        end

        def url_owners_class
          return instance.class unless settings.enforce_uniqueness_on_sti_base_class

          klass = instance.class
          while klass.superclass < orm_class
            klass = klass.superclass
          end
          klass
        end

        def write_attribute(instance, attribute, value)
          instance.send :write_attribute, attribute, value
        end

        def write_url_attribute(value)
          write_attribute instance, settings.url_attribute, value
        end
      end
    end
  end
end
