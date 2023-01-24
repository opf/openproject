#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class Settings::UpdateService < BaseServices::BaseContracted
  def initialize(user:)
    super user:,
          contract_class: Settings::UpdateContract
  end

  def after_validate(params, call)
    params.keys.each(&method(:remember_previous_value))
    call
  end

  # We will have a problem with error handling on the form.
  # How can we still display the user changed values in case the form is not successfully saved?
  def persist(call)
    params.each do |name, value|
      set_setting_value(name, value)
    end
    call
  end

  def after_perform(call)
    super.tap do
      params.each_key do |name|
        run_on_change_callback(name)
      end
    end
  end

  private

  def remember_previous_value(name)
    previous_values[name] = Setting[name]
  end

  def set_setting_value(name, value)
    Setting[name] = derive_value(value)
  end

  def previous_values
    @previous_values ||= {}
  end

  def run_on_change_callback(name)
    if (definition = Settings::Definition[name]) && definition.on_change
      definition.on_change.call(previous_values[name])
    end
  end

  def derive_value(value)
    case value
    when Array, Hash
      # remove blank values in array, hash settings
      value.compact_blank!
    else
      value.strip
    end
  end
end
