#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Queries::Projects::ProjectQuery < ApplicationRecord
  include Queries::BaseQuery
  include Queries::Serialization::Hash

  belongs_to :user

  serialize :filters, coder: Queries::Serialization::Filters.new(self)
  serialize :orders, coder: Queries::Serialization::Orders.new(self)
  serialize :selects, coder: Queries::Serialization::Selects.new(self)

  def self.model
    Project
  end

  def default_scope
    # Cannot simply use .visible here as it would
    # filter out archived projects for everybody.
    if User.current.admin?
      super
    else
      # Directly appending the .visible scope adds a
      # distinct which then requires every column used e.g. for ordering
      # to be in select.
      super.where(id: Project.visible)
    end
  end
end
