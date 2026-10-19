# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "simplecov"

module RSpecCoverage
  ROOT = File.expand_path("../..", __dir__).freeze

  def self.configure
    SimpleCov.configure do
      root ROOT
      enable_coverage :branch, :eval
      cover "app/**/*.rb", "lib/**/*.rb", "lib_static/**/*.rb", "modules/*/{app,lib}/**/*.rb"
      cover %r{\A/?(?:app|lib|lib_static|modules/[^/]+/(?:app|lib))/.*\.erb\z}
      group "Application", %r{\A/?app/}
      group "Libraries", %r{\A/?lib/}
      group "Static libraries", %r{\A/?lib_static/}
      group "Modules", %r{\A/?modules/}
      parallel_tests false
      formatters []
    end
  end
end
