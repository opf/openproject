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
  validates_presence_of :encoded_license
  validate :load_license

  after_save :update_license_service
  after_destroy :update_license_service

  def self.current
    License.order('created_at DESC').first
  end

  def load_license
    OpenProject::License.import(encoded_license)
  rescue OpenProject::License::ImportError => error
    Rails.logger.error "Failed to load license: #{error}"
    errors.add(:encoded_license, :import_failed)
    nil
  end

  private

  def update_license_service
    LicenseService.instance.update
  end
end
