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

module IfcModelsHelper
  def ifc_model_data_object(all_models, shown_models)
    all_converted_models = converted_ifc_models(all_models)

    {
      models: ifc_model_models(all_converted_models),
      shown_models: ifc_shown_models(all_converted_models, shown_models),
      projects: [{ id: @project.identifier, name: @project.name }],
      xkt_attachment_ids: ifc_model_xkt_attachment_ids(all_converted_models),
      permissions: {
        manage_ifc_models: User.current.allowed_in_project?(:manage_ifc_models, @project),
        manage_bcf: User.current.allowed_in_project?(:manage_bcf, @project)
      }
    }
  end

  def converted_ifc_models(ifc_models)
    ifc_models.select(&:converted?)
  end

  def ifc_model_models(all_models)
    all_converted_models = converted_ifc_models(all_models)

    all_converted_models.map do |ifc_model|
      {
        id: ifc_model.id,
        name: ifc_model.title,
        default: ifc_model.is_default
      }
    end
  end

  def ifc_shown_models(all_models, shown_models)
    if shown_models.empty?
      return all_models.select(&:is_default).map(&:id)
    end

    converted_ifc_models(all_models)
      .select { |model| shown_models.include?(model.id) }
      .map(&:id)
  end

  def ifc_model_xkt_attachment_ids(models)
    models.to_h { |model| [model.id, model.xkt_attachment.id] }
  end
end
