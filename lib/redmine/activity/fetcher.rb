module Redmine
  module Activity
    # Class used to retrieve activity events
    class Fetcher
      attr_reader :user, :project, :scope
      
      # Needs to be unloaded in development mode
      @@constantized_providers = Hash.new {|h,k| h[k] = Redmine::Activity.providers[k].collect {|t| t.constantize } }
      
      def initialize(user, options={})
        options.assert_valid_keys(:project, :with_subprojects, :author)
        @user = user
        @project = options[:project]
        @options = options
        
        @scope = event_types
      end
      
      # Returns an array of available event types
      def event_types
        return @event_types unless @event_types.nil?
        
        @event_types = Redmine::Activity.available_event_types
        if @project
          @event_types = @event_types.select do |o|
            @project.self_and_descendants.detect do |p|
              permissions = constantized_providers(o).collect do |p|
                p.activity_provider_options[o].try(:[], :permission)
              end.compact
              return @user.allowed_to?("view_#{o}".to_sym, @project) if permissions.blank?
              permissions.all? {|p| @user.allowed_to?(p, @project) } if @project
            end
          end
        end
        @event_types
      end
      
      # Yields to filter the activity scope
      def scope_select(&block)
        @scope = @scope.select {|t| yield t }
      end
      
      # Sets the scope
      # Argument can be :all, :default or an array of event types
      def scope=(s)
        case s
        when :all
          @scope = event_types
        when :default
          default_scope!
        else
          @scope = s & event_types
        end
      end
      
      # Resets the scope to the default scope
      def default_scope!
        @scope = Redmine::Activity.default_event_types
      end
      
      # Returns an array of events for the given date range
      # sorted in reverse chronological order
      def events(from = nil, to = nil, options={})
        e = []
        @options[:limit] = options[:limit]
        
        @scope.each do |event_type|
          constantized_providers(event_type).each do |provider|
            e += provider.find_events(event_type, @user, from, to, @options)
          end
        end
        
        e.sort! {|a,b| b.event_datetime <=> a.event_datetime}
        
        if options[:limit]
          e = e.slice(0, options[:limit])
        end
        e
      end
      
      private
      
      def constantized_providers(event_type)
        @@constantized_providers[event_type]
      end
    end
  end
end
