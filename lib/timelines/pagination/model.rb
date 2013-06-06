# This module includes some boilerplate code for pagination using scopes.
# #search_scope has to be overridden by the model itself and MUST return an
# actual scope (i.e. scope in Rails3 or named_scope in Rails2) or its corresponding hash.

module Timelines::Pagination::Model

  def self.included(base)
    base.extend self
  end

  def self.extended(base)
    base.instance_eval do
      unloadable

      def paginate_scope!(scope, options = {})
        limit = options.fetch(:page_limit) || 10
        page = options.fetch(:page) || 1
        scope = (scope.respond_to?(:scope) ? scope.scope(:find) : scope)
        paginate({ :per_page => limit, :page => page }.merge(scope))
      end

      def search_scope(query)
        raise NotImplementedError, "Override in subclass #{self.name}"
      end
    end
  end
end
