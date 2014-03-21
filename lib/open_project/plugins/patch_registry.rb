#-- copyright
# OpenProject Plugins Plugin
#
# Copyright (C) 2013 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
