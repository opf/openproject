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
class License < ActiveRecord::Base
  class << self
    def current
      set_current_license unless defined?(@@current_license)
      @@current_license
    end

    def show_banners
      !current || current.expired?
    end

    def set_current_license
      license = License.order('created_at DESC').first

      @@current_license =
        if license && license.license_object
          license
        end
    end
  end

  validates_presence_of :encoded_license
  validate :valid_license_object

  after_save :set_current_license
  after_destroy :set_current_license

  delegate :will_expire?,
           :expired?,
           :licensee,
           :mail,
           :issued_at,
           :starts_at,
           :expires_at,
           :restrictions,
           to: :license_object

  def license_object
    @license_object = load_license unless defined?(@license_object)
    @license_object
  end

  def allows_to?(ability)
    case ability
    when :define_custom_style
      # Every valid license allows for defining custom styles
      !expired?
    end
  end

  private

  delegate :set_current_license, to: :class

  def load_license
    OpenProject::License.import(encoded_license)
  rescue OpenProject::License::ImportError => error
    Rails.logger.error "Failed to load license: #{error}"
    nil
  end

  def valid_license_object
    errors.add(:encoded_license, :unreadable) unless license_object
  end
end
