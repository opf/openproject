module PrependEngineViews
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :add_engine_view_paths, :prepend
    end
  end

  module InstanceMethods
    # Patch Rails so engine's views are prepended to the view_path,
    # thereby letting plugins override application views
    def add_engine_view_paths_with_prepend
      paths = ActionView::PathSet.new(engines.collect(&:view_path))
      ActionController::Base.view_paths.unshift(*paths)
      ActionMailer::Base.view_paths.unshift(*paths) if configuration.frameworks.include?(:action_mailer)
    end
  end
end

Rails::Plugin::Loader.send :include, PrependEngineViews

