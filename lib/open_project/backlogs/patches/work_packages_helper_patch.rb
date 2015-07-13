#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Backlogs::Patches::WorkPackagesHelperPatch
  def self.included(base)
    base.class_eval do
      def work_package_form_all_middle_attributes_with_backlogs(form, work_package, locals = {})
        attributes = work_package_form_all_middle_attributes_without_backlogs(form, work_package, locals)

        if work_package.backlogs_enabled?
          attributes << work_package_form_remaining_hours_attribute(form, work_package, locals)
          attributes << work_package_form_story_points_attribute(form, work_package, locals)
        end

        attributes.compact
      end

      def work_package_form_remaining_hours_attribute(form, work_package, _)
        field = work_package_form_field {
          options = { placeholder: l(:label_hours) }
          options[:disabled] = 'disabled' unless work_package.leaf?

          form.text_field(:remaining_hours, options)
        }

        WorkPackagesHelper::WorkPackageAttribute.new(:remaining_hours, field)
      end

      def work_package_form_story_points_attribute(form, work_package, _)
        return unless work_package.is_story?

        field = work_package_form_field {
          form.text_field(:story_points)
        }

        WorkPackagesHelper::WorkPackageAttribute.new(:story_points, field)
      end

      alias_method_chain :work_package_form_all_middle_attributes, :backlogs
    end
  end
end

WorkPackagesHelper.send(:include, OpenProject::Backlogs::Patches::WorkPackagesHelperPatch)
