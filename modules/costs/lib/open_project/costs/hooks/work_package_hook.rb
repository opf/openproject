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

# Hooks to attach to the Redmine WorkPackages.
class OpenProject::Costs::Hooks::WorkPackageHook < Redmine::Hook::ViewListener
  # Renders the Cost Object subject and basic costs information
  # render_on :view_work_packages_show_details_bottom, :partial => 'hooks/costs/view_work_packages_show_details_bottom'

  # Renders a select tag with all the Cost Objects for the bulk edit page
  render_on :view_work_packages_bulk_edit_details_bottom, partial: 'hooks/costs/view_work_packages_bulk_edit_details_bottom'

  render_on :view_work_packages_move_bottom, partial: 'hooks/costs/view_work_packages_move_bottom'

  render_on :view_work_package_overview_attributes, partial: 'hooks/costs/view_work_package_overview_attributes'

  # Updates the cost object after a move
  #
  # Context:
  # * params => Request parameters
  # * work_package => WorkPackage to move
  # * target_project => Target of the move
  # * copy => true, if the work_packages are copied rather than moved
  def controller_work_packages_move_before_save(context = {})
    # FIXME: In case of copy==true, this will break stuff if the original work_package is saved

    cost_object_id = context[:params] && context[:params][:cost_object_id]
    case cost_object_id
    when '' # a.k.a "(No change)"
      # cost objects HAVE to be changed if move is performed across project boundaries
      # as the are project specific
      context[:work_package].cost_object_id = nil unless (context[:work_package].project == context[:target_project])
    when 'none'
      context[:work_package].cost_object_id = nil
    else
      context[:work_package].cost_object_id = cost_object_id
    end
  end

  # Saves the Cost Object assignment to the work_package
  #
  # Context:
  # * :work_package => WorkPackage being saved
  # * :params => HTML parameters
  #
  def controller_work_packages_bulk_edit_before_save(context = {})
    case true

    when context[:params][:cost_object_id].blank?
      # Do nothing
    when context[:params][:cost_object_id] == 'none'
      # Unassign cost_object
      context[:work_package].cost_object = nil
    else
      context[:work_package].cost_object = CostObject.find(context[:params][:cost_object_id])
    end

    ''
  end

  # Cost Object changes for the journal use the Cost Object subject
  # instead of the id
  #
  # Context:
  # * :detail => Detail about the journal change
  #
  def helper_work_packages_show_detail_after_setting(context = {})
    # FIXME: Overwritting the caller is bad juju
    if (context[:detail].prop_key == 'cost_object_id')
      if context[:detail].value.to_i.to_s == context[:detail].value.to_s
        d = CostObject.find_by_id(context[:detail].value)
        context[:detail].value = d.subject unless d.nil? || d.subject.nil?
      end

      if context[:detail].old_value.to_i.to_s == context[:detail].old_value.to_s
        d = CostObject.find_by_id(context[:detail].old_value)
        context[:detail].old_value = d.subject unless d.nil? || d.subject.nil?
      end
    end
    ''
  end
end
