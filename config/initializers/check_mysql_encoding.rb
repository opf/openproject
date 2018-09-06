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

if OpenProject::Database.mysql?
  return if ActiveRecord::Type::Boolean.new.cast(ENV['OPENPROJECT_TESTING_NO_HEADLESS'])

  mysql_version = OpenProject::Database.semantic_version
  utf8mb4_version = OpenProject::Database.semantic_version '5.7.0'
  encoding = ActiveRecord::Base.connection_config[:encoding]
  expected = nil

  if mysql_version < utf8mb4_version && encoding != "utf8"
    expected = "utf8"
  elsif mysql_version >= utf8mb4_version && encoding != "utf8mb4"
    expected = "utf8mb4"
  end

  if expected.present?
    message = <<-MESSAGE

     *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *

     *   OpenProject requires UTF-8 encoding set on MySQL < 5.7              *
         and UTF-8mb4 beyond that. Please ensure having set
     *                                                                       *
             #{Rails.env}:
     *         encoding: #{expected}                                         *

     *   in config/database.yml                                              *

     *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *

    MESSAGE

    raise message
  end
end
