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

##
# Adds and removes modules from a project
#
module Projects
  class EnabledModulesService < ::BaseServices::BaseContracted
    def initialize(user:, model:, contract_class: ::Projects::EnabledModulesContract)
      super(user:, contract_class:)
      self.model = model
    end

    private

    def before_perform(params, _service_result)
      model.enabled_module_names = params[:enabled_modules]
      super
    end

    def persist(call)
      # Nothing to do any more
      call
    end

    def after_perform(call)
      super.tap do
        # Ensure the project is touched to update its cache key
        model.touch
      end
    end
  end
end
