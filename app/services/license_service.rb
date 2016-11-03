#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2016 the OpenProject Foundation (OPF)
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
require 'singleton'

class LicenseService
  include Singleton

  @license = nil

  def initialize
    # Read the license from a file.
    load_license_from_file
  end

  def update
    load_license_from_file
  end

  def load_license_from_file
    begin
      # TODO: Try to find the first *.openproject-license file
      data = File.read(File.join(Rails.root, "ForkmergeSLU.openproject-license") )
      @license = OpenProject::License.import(data)
    rescue => e
      Rails.logger.error "We ran into problems with your license file:\n\t#{e.massage}\nWe continue without license."
    end
  end

  def method_missing(m, *args, &block)
    if @license && @license.respond_to?(m)
      @license.send(m, *args, &block)
    else
      raise NoMethodError
    end
  end

end
