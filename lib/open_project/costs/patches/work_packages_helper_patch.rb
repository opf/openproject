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

module OpenProject::Costs::Patches::WorkPackagesHelperPatch
  def self.included(base)
    base.class_eval do
      def work_package_form_all_middle_attributes_with_costs(form, work_package, locals = {})
        attributes = work_package_form_all_middle_attributes_without_costs(form, work_package, locals)

        if work_package.project.module_enabled?(:costs_module)
          attributes << work_package_form_budget_attribute(form, work_package, locals)
        end

        attributes.compact
      end

      def work_package_form_budget_attribute(form, _work_package, _locals)
        field = work_package_form_field {
          options = CostObject.find_all_by_project_id(@project, order: 'subject ASC').map { |d| [d.subject, d.id] }
          form.select(:cost_object_id, options, include_blank: true)
        }

        WorkPackagesHelper::WorkPackageAttribute.new(:cost_object_id, field)
      end

      alias_method_chain :work_package_form_all_middle_attributes, :costs
    end
  end
end

WorkPackagesHelper.send(:include, OpenProject::Costs::Patches::WorkPackagesHelperPatch)
