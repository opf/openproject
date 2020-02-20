#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module Bim::Bcf::API::V2_1::Endpoints
  module ModifyMixin
    private

    def deduce_parse_service
      ::Bim::Bcf::API::V2_1::ParseResourceParamsService
    end

    def deduce_process_service
      "::Bim::Bcf::#{deduce_backend_namespace}::#{update_or_create}Service".constantize
    end

    def deduce_in_and_out_representer
      "::Bim::Bcf::API::V2_1::#{deduce_api_namespace}::SingleRepresenter".constantize
    end

    alias_method :deduce_parse_representer, :deduce_in_and_out_representer
    alias_method :deduce_render_representer, :deduce_in_and_out_representer
  end
end
