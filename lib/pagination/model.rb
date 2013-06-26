#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# This module includes some boilerplate code for pagination using scopes.
# #search_scope has to be overridden by the model itself and MUST return an
# actual scope (i.e. scope in Rails3 or named_scope in Rails2) or its corresponding hash.

module Pagination::Model

  def self.included(base)
    base.extend self
  end

  def self.extended(base)
    base.instance_eval do
      unloadable

      def paginate_scope!(scope, options = {})
        limit = options.fetch(:page_limit) || 10
        page = options.fetch(:page) || 1

        scope.paginate({ :per_page => limit, :page => page }) 
      end

      def search_scope(query)
        raise NotImplementedError, "Override in subclass #{self.name}"
      end
    end
  end
end
