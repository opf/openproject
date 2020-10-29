module Cell
  def self.rails_version
    Gem::Version.new(ActionPack::VERSION::STRING)
  end

  # These methods are automatically added to all controllers and views.
  module RailsExtensions
    module ActionController
      def cell(name, model=nil, options={}, constant=::Cell::ViewModel, &block)
        options[:context] ||= {}
        options[:context][:controller] = self

        constant.cell(name, model, options, &block)
      end

      def concept(name, model=nil, options={}, &block)
        cell(name, model, options, ::Cell::Concept, &block)
      end
    end

    module ActionView
      # Returns the cell instance for +name+. You may pass arbitrary options to your
      # cell.
      #
      #   = cell(:song, title: "Creeping Out Sara").(:show)
      def cell(name, *args, &block)
        controller.cell(name, *args, &block)
      end

      # # See Cells::Rails::ActionController#render_cell.
      # def render_cell(name, state, *args, &block)
      #   ::Cell::Rails.render_cell(name, state, controller, *args, &block)
      # end

      def concept(name, *args, &block)
        controller.concept(name, *args, &block)
      end
    end

    # Gets included into Cell::ViewModel in a Rails environment.
    module ViewModel
      extend ActiveSupport::Concern

      # DISCUSS: who actually uses forgery protection with cells? it is not working since 4, anyway?
      # include ActionController::RequestForgeryProtection
      included do
        extend Uber::Delegates
        delegates :parent_controller, :session, :params, :request, :config, :env, :url_options, :default_url_options
        # forgery protection.
        delegates :parent_controller, :request_forgery_protection_token
      end

      def call(*)
        super.html_safe
      end

      def parent_controller
        context[:controller]
      end
      alias_method :controller, :parent_controller

      def perform_caching?
        ::ActionController::Base.perform_caching
      end

      def cache_store  # we want to use DI to set a cache store in cell/rails.
        ::ActionController::Base.cache_store
      end

      # In Ruby 2.4.0+, Forwardable prints a warning when you delegate
      # to a private or protected method - so `delegates :protect_against_forgery?`
      # or `delegates :form_authenticity_token` will print warnings all
      # over the place
      #
      # This workaround prevents warnings being printed
      def protect_against_forgery?
        controller.send(:protect_against_forgery?)
      end

      def form_authenticity_token(*args)
        controller.send(:form_authenticity_token, *args)
      end

      module ClassMethods
        def expand_cache_key(key)
          ::ActiveSupport::Cache.expand_cache_key(key, :cells)
        end
      end
    end

    # In Rails, there are about 10 different implementations of #url_for. Rails doesn't like the idea of objects, so they
    # have helpers in modules. Those module are now included sequentially into other modules and/or classes. While they
    # get included, they might or might not include methods, depending on the including module/class
    # (example here: https://github.com/rails/rails/blob/cad20f720c4c6e04584253cd0a23f22b3d43ab0f/actionpack/lib/action_dispatch/routing/url_for.rb#L87).
    #
    # The outcome is that several module override #url_for, and if you're lucky, this works. If you're not, then #url_for breaks
    # due to a raise in one of its basic implementations, introduced in 3.x, fixed in 4.0 and then re-introduced in 4.2
    #
    # This is extremely frustrating as no one in Rails core seems to tackle this problem and introduces a url object instead
    # of this module madness. I have to constantly test and fix it in Cells. With the module below, I'll stop doing this.
    #
    # Either Rails works with Cells and we fix this in form of a URL object that gets passed into the cell (I'm happy with
    # a global object here, too! Wow!) or URL helpers will stop working in Cells and a lot of people will be unhappy.
    #
    # Anyway, this is the reason we need this patch module. If you have trouble with URLs in Cells, then please ask Rails to
    # fix their implementation. Thank you.
    module HelpersAreShit
      def url_for(options = nil) # from ActionDispatch:R:UrlFor.
        case options
          when nil
            _routes.url_for(url_options.symbolize_keys)
          when Hash
            _routes.url_for(options.symbolize_keys.reverse_merge!(url_options))
          when String
            options
          when Array
            polymorphic_url(options, options.extract_options!)
          else
            polymorphic_url(options)
        end
      end
    end
  end
end
