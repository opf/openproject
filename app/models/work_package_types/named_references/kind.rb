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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  module NamedReferences
    Kind = Data.define(:model_class_name, :association, :project_owned, :i18n_scope, :dom_key, :icon, :locale_keys) do
      def model_class = model_class_name.constantize

      def route_key = model_class.model_name.route_key.to_sym

      def query_class = "Queries::#{model_class_name.pluralize}::#{model_class_name}Query".constantize

      def t(key, **)
        I18n.t(locale_keys.fetch(key.to_sym) { "#{i18n_scope}.#{key}" }, **)
      end
    end

    Kind::WORKFLOW = Kind.new(
      model_class_name: "Workflow",
      association: :workflow,
      project_owned: true,
      i18n_scope: "workflows",
      dom_key: "workflow",
      icon: :workflow,
      locale_keys: { label_plural: :label_workflow_plural }
    )

    Kind::FORM = Kind.new(
      model_class_name: "FormConfiguration",
      association: :form_configuration,
      project_owned: false,
      i18n_scope: "forms",
      dom_key: "form",
      icon: :rows,
      locale_keys: {}
    )
  end
end
