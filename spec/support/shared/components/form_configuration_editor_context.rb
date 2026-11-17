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

# Builds the context a form editor component renders in: editable on the form's own
# page, read-only on a variant screen. Override `readonly` per context. A read-only
# context carries the variant's real exclusions, whose toggles need the variant scope.
RSpec.shared_context "with a form configuration editor context" do
  include_context "with variant scope"

  let(:variant) { create(:type).default_variant }
  let(:readonly) { false }
  let(:editor_context) do
    if readonly
      WorkPackageTypes::FormConfiguration::EditorContext.for_variant(variant, scope_project: nil)
    else
      WorkPackageTypes::FormConfiguration::EditorContext.new(form_configuration: variant.form_configuration)
    end
  end
end
