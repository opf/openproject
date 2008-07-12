# The way ActionMailer is coded in terms of finding templates is very restrictive, to the point
# where all templates for rendering must exist under the single base path. This is difficult to
# work around without re-coding significant parts of the action mailer code.
#
# ---
#
# The MailTemplates module overrides two (private) methods from ActionMailer to enable mail 
# templates within plugins:
#
# [+template_path+]             which now produces the contents of #template_paths
# [+initialize_template_class+] which now find the first matching template and creates 
#                               an ActionVew::Base instance with the correct view_paths
#
# Ideally ActionMailer would use the same template-location logic as ActionView, and the same
# view paths as ActionController::Base.view_paths, but it currently does not.
module Engines::RailsExtensions::ActionMailer
  def self.included(base) #:nodoc:
    base.class_eval do
      # TODO commented this out because it seems to break ActionMailer
      # how can this be fixed?
      
      alias_method_chain :template_path, :engine_additions
      alias_method_chain :initialize_template_class, :engine_additions
    end
  end

  private
  
    #--
    # ActionMailer::Base#create uses two mechanisms to determine the proper template file(s)
    # to load. Firstly, it searches within the template_root for files that much the explicit
    # (or implicit) part encodings (like signup.text.plain.erb for the signup action). 
    # This is how implicit multipart emails are built, by the way.
    #
    # Secondly, it then creates an ActionMailer::Base instance with it's view_paths parameter
    # set to the template_root, so that ActionMailer will then take over rendering the
    # templates.
    #
    # Ideally, ActionMailer would pass the same set of view paths as it gets in a normal
    # request (i.e. ActionController::Base.view_paths), so that all possible view paths
    # were searched. However, this seems to introduce some problems with helper modules.
    #
    # So instead, and because we have to fool these two independent parts of ActionMailer,
    # we fudge with the mechanisms it uses to find the templates (via template_paths, and
    # template_path_with_engine_additions), and then intercept the creation of the ActionView
    # instance so we can set the view_paths (in initialize_template_class_with_engine_additions).
    #++
  
    # Returns all possible template paths for the current mailer, including those
    # within the loaded plugins.
    def template_paths
      paths = Engines.plugins.by_precedence.map { |p| "#{p.directory}/app/views/#{mailer_name}" }
      paths.unshift(template_path_without_engine_additions) unless Engines.disable_application_view_loading
      paths
    end

    # Return something that Dir[] can glob against. This method is called in 
    # ActionMailer::Base#create! and used as part of an argument to Dir. We can
    # take advantage of this by using some of the features of Dir.glob to search
    # multiple paths for matching files.
    def template_path_with_engine_additions
      "{#{template_paths.join(",")}}"
    end

    # Return an instance of ActionView::Base with the view paths set to all paths
    # in ActionController::Base.view_paths (i.e. including all plugin view paths)
    def initialize_template_class_with_engine_additions(assigns)
      # I'd like to just return this, but I get problems finding methods in helper
      # modules if the method implemention from the regular class is not called
      # 
      # ActionView::Base.new(ActionController::Base.view_paths.dup, assigns, self)
      renderer = initialize_template_class_without_engine_additions(assigns)
      renderer.finder.view_paths = ActionController::Base.view_paths.dup
      renderer
    end
end

# We don't need to do this if ActionMailer hasn't been loaded.
if Object.const_defined?(:ActionMailer) 
  module ::ActionMailer #:nodoc:
    class Base #:nodoc:
      include Engines::RailsExtensions::ActionMailer
    end
  end
end