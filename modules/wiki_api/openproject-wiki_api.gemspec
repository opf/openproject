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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Gem::Specification.new do |s|
  s.name        = "openproject-wiki_api"
  s.version     = "1.0.0"

  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.org"
  s.summary     = "OpenProject Wiki API"
  s.description = "Extends the OpenProject API v3 with a full CRUD interface " \
                  "for wiki pages: project listing, hierarchy tree, create/update/" \
                  "delete, revision history, lock/move/copy operations and " \
                  "PostgreSQL full-text search."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(README.md)
  s.metadata["rubygems_mfa_required"] = "true"
end
