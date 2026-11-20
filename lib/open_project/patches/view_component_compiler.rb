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

module OpenProject
  module Patches
    # Without this patch, components inheriting from `Primer::BaseComponent` without calling its
    # `#initialize` run into a `NoMethodError` when responding to a request for a format other than `:html`,
    # e.g. for a turbo stream.
    # For the problem to occur all of the following conditions need to be met:
    # 1. The class inherits from a component whose #call reads instance vars set in its own `#initialize`.
    #    `Primer::BaseComponent` is such a case but it is not Primer specific.
    # 2. The class' `#initialize` doesn't call super, so those variables are never set.
    #    This currently is the case both in `SegmentedControl::Item` from Primer itself as well as in our
    #    `Grids::WidgetComponent`.
    # 3. It has its own template. As long as the template's format is hit, it hides the problem:
    #    the class normally renders via its sidecar ERB.
    # 4. It's rendered under a lookup context whose format its own template doesn't match.
    #
    # This seems to be a bug in view_component as before 4.21.0 a sidecar's template was used for every format.
    # Issue reported as https://github.com/ViewComponent/view_component/issues/2799
    module ViewComponentCompiler
      private

      def gather_templates
        templates = super
        inherited, own = templates.partition(&:requires_compiled_superclass?)
        return templates if inherited.empty? || own.empty?

        own_keys = own.map { |template| openproject_template_key(template) }
        templates.reject! do |template|
          template.requires_compiled_superclass? && own_keys.include?(openproject_template_key(template))
        end

        templates
      end

      def openproject_template_key(template)
        [template.variant, template.format || :html]
      end
    end
  end
end

OpenProject::Patches.patch_gem_version "view_component", "4.23.0" do
  ViewComponent::Compiler.prepend OpenProject::Patches::ViewComponentCompiler
end
