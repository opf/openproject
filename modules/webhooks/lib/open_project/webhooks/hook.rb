#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
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

module OpenProject::Webhooks
  class Hook
    attr_accessor :name, :callback

    def initialize(name, &callback)
      super()
      @name = name
      @callback = callback
    end

    def relative_url
      "webhooks/#{name}"
    end

    def handle(request = Hash.new, params = Hash.new, user = nil)
      callback.call self, request, params, user
    end

  end
end
