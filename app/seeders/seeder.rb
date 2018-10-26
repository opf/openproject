#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Seeder
  def seed!
    if applicable?
      seed_data!
    else
      puts "   *** #{not_applicable_message}"
    end
  end

  def seed_data!
    raise NotImplementedError
  end

  def applicable?
    true
  end

  def not_applicable_message
    "Skipping #{self.class.name}"
  end

  protected

  ##
  # Translate the given string with the fixed interpolation for base_url
  # Deep interpolation is required in order for interpolations on hashes to work!
  def translate_with_base_url(string)
    I18n.t(string, deep_interpolation: true, base_url: OpenProject::Configuration.rails_relative_url_root)
  end
end
