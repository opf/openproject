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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Purpose: When returning a collection of file links, our standard index endpoint needs a query class to have a
# reference to the embedded model.

# The namespace is programmatically derived from the model name. See app/services/params_to_query_service.rb:130
class Queries::Storages::FileLinks::FileLinkQuery
  include Queries::BaseQuery
  include Queries::UnpersistedQuery

  class << self
    # We need to overwrite the model method, as the standard implementation cannot derive the name from nested
    # namespaces. See app/models/queries/base_query.rb:31
    def model
      @model ||= ::Storages::FileLink
    end
  end
end
