#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'reform'
require 'reform/form/coercion'

module API
  module V3
    module CostObjects
      class CostObjectModel < Reform::Form
        property :project_id, type: Integer
        property :author, type: String
        property :subject, type: String
        property :description, type: String
        property :type, type: String
        property :fixed_date, type: DateTime
        property :created_on, type: DateTime
        property :updated_on, type: DateTime

        def author
          ::API::V3::Users::UserModel.new(model.author) unless model.author.nil?
        end
      end
    end
  end
end
