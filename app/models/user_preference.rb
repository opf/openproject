#-- encoding: UTF-8
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

class UserPreference < ActiveRecord::Base
  belongs_to :user
  serialize :others

  validates_presence_of :user

  attr_accessible :user

  # attributes that have their own column
  attr_accessible :hide_mail, :time_zone, :impaired

  # shortcut methods to others hash
  attr_accessible :comments_sorting, :warn_on_leaving_unsaved, :theme

  after_initialize :init_other_preferences

  def [](attr_name)
    attribute_present?(attr_name) ? super : others[attr_name]
  end

  def []=(attr_name, value)
    attribute_present?(attr_name) ? super : others[attr_name] = value
  end

  def comments_sorting
    others[:comments_sorting]
  end

  def comments_sorting=(order)
    others[:comments_sorting] = order
  end

  def theme
    others[:theme] || OpenProject::Themes.application_theme_identifier
  end

  def theme=(order)
    others[:theme] = order
  end

  def warn_on_leaving_unsaved
    others.fetch(:warn_on_leaving_unsaved) { '1' }
  end

  def warn_on_leaving_unsaved=(value)
    others[:warn_on_leaving_unsaved] = value
  end

  private

  def init_other_preferences
    self.others ||= { no_self_notified: true }
  end
end
