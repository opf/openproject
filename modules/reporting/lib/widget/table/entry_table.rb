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

class ::Widget::Table::EntryTable < ::Widget::Table
  FIELDS = [:spent_on, :user_id, :activity_id, :work_package_id, :comments, :project_id]

  detailed_table self

  def render
    content = content_tag :div, class: 'generic-table--container -with-footer' do
      content_tag :div, class: 'generic-table--results-container' do
        table = content_tag :table, class: 'generic-table',
                                    id: 'sortable-table' do
          concat colgroup
          concat head
          concat foot
          concat body
        end
        table
      end
    end
    write content
  end

  def colgroup
    content_tag :colgroup do
      FIELDS.each do
        concat content_tag(:col, 'highlight-col' => true) {}
      end
      concat content_tag(:col, 'highlight-col' => true) {}
      concat content_tag(:col, 'highlight-col' => true) {}
      concat content_tag(:col) {}
    end
  end

  def head
    content_tag :thead do
      content_tag :tr do
        FIELDS.map do |field|
          concat content_tag(:th) {
            content_tag(:div, class: 'generic-table--sort-header-outer') do
              content_tag(:div, class: 'generic-table--sort-header') do
                content_tag(:span, label_for(field))
              end
            end
          }
        end
        concat content_tag(:th) {
          content_tag(:div, class: 'generic-table--sort-header-outer') do
            content_tag(:div, class: 'generic-table--sort-header') do
              content_tag(:span, cost_type.try(:unit_plural) || l(:units))
            end
          end
        }
        concat content_tag(:th) {
          content_tag(:div, class: 'generic-table--sort-header-outer') do
            content_tag(:div, class: 'generic-table--sort-header') do
              content_tag(:span, CostEntry.human_attribute_name(:costs))
            end
          end
        }
        hit = false
        @subject.each_direct_result do |result|
          next if hit
          if entry_for(result).editable_by? User.current
            concat content_tag(:th, class: 'unsortable') {
              content_tag(:div, '', class: 'generic-table--empty-header')
            }
            hit = true
          end
        end
      end
    end
  end

  def foot
    content_tag :tfoot do
      content_tag :tr do
        if show_result(@subject, 0) != show_result(@subject)
          concat content_tag(:td, '', colspan: FIELDS.size)
          concat content_tag(:td) {
            concat content_tag(:div,
                               show_result(@subject),
                               class: 'inner generic-table--footer-outer')
          }
          concat content_tag(:td) {
            concat content_tag(:div,
                               show_result(@subject, 0),
                               class: 'result generic-table--footer-outer')
          }
        else
          concat content_tag(:td, '', colspan: FIELDS.size + 1)
          concat content_tag(:td) {
            concat content_tag(:div,
                               show_result(@subject),
                               class: 'result generic-table--footer-outer')
          }
        end
        concat content_tag(:th, '', class: 'unsortable')
      end
    end
  end

  def body
    content_tag :tbody do
      rows = ''.html_safe
      @subject.each_direct_result do |result|
        rows << (content_tag(:tr) do
          ''.html_safe
          FIELDS.each do |field|
            concat content_tag(:td, show_field(field, result.fields[field.to_s]).html_safe,
                               :'raw-data' => raw_field(field, result.fields[field.to_s]),
                               class: 'left')
          end
          concat content_tag :td, show_result(result, result.fields['cost_type_id'].to_i).html_safe,
                             class: 'units right',
                             :'raw-data' => result.units
          concat content_tag :td,
                             (show_result(result, 0)).html_safe,
                             class: 'currency right',
                             :'raw-data' => result.real_costs
          concat content_tag :td, icons(result)
        end)
      end
      rows
    end
  end

  def icons(result)
    icons = ''
    with_project(result.fields['project_id']) do
      if entry_for(result).editable_by? User.current
        if controller_for(result.fields['type']) == 'costlog'
          icons = link_to(icon_wrapper('icon-context icon-edit', l(:button_edit)),
                          action_for(result, action: 'edit'),
                          class: 'no-decoration-on-hover',
                          title: l(:button_edit))

          icons << link_to(icon_wrapper('icon-context icon-delete', l(:button_delete)),
                           (action_for(result, action: 'destroy')
                              .reverse_merge(authenticity_token: form_authenticity_token)),
                           data: { confirm: l(:text_are_you_sure) },
                           method: :delete,
                           class: 'no-decoration-on-hover',
                           title: l(:button_delete))
        else
          icons = content_tag(:'time-entry--trigger-actions-entry',
                              '',
                              data: { entry: result['id'] })
        end
      end
    end
    icons
  end
end
