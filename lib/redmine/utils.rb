module Redmine
  module Utils
    class << self
      # Returns the relative root url of the application
      def relative_url_root
        ActionController::Base.respond_to?('relative_url_root') ?
          ActionController::Base.relative_url_root.to_s :
          ActionController::AbstractRequest.relative_url_root.to_s
      end
      
      # Sets the relative root url of the application
      def relative_url_root=(arg)
        if ActionController::Base.respond_to?('relative_url_root=')
          ActionController::Base.relative_url_root=arg
        else
          ActionController::AbstractRequest.relative_url_root=arg
        end
      end
    end
  end
end
