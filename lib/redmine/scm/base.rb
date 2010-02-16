module Redmine
  module Scm
    class Base
      class << self

        def all
          @scms
        end

        # Add a new SCM adapter and repository
        def add(scm_name)
          @scms ||= []
          @scms << scm_name
        end

        # Remove a SCM adapter from Redmine's list of supported scms
        def delete(scm_name)
          @scms.delete(scm_name)
        end
      end
    end
  end
end
