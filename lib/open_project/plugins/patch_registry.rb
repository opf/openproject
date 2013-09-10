#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.md for more details.
#++

module OpenProject::Plugins
  module PatchRegistry
    def self.register(target, patch)
      #patches[target] << patch

      ActiveSupport.on_load(target) do
        require_dependency patch
        constant = patch.camelcase.constantize

        target.to_s.camelcase.constantize.send(:include, constant)
      end
    end

    protected

    def self.patches
      @patches ||= Hash.new do |h, k|
        h[k] = []
      end
    end
  end
end
