#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'uri'

##
# :touch given objects *once* after the request has completed.
module Concerns::TouchLater
  extend ActiveSupport::Concern

  included do
    after_filter :touch_now
  end

  def touch_later(object)
    RequestStore[:touchable_objects] = touchables.merge(object.id => object)
  end

  private

  def touch_now
    touchables.each do |_, object|
      object.touch
    end
  rescue => e
    Rails.logger.error { "#{object.model_name.human} #{object.id} is untouchable! #{e.message}" }
  end

  def touchables
    RequestStore.fetch(:touchable_objects) do
      {}
    end
  end
end
