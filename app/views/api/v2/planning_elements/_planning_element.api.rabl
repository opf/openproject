#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# This is an intentional duplication from index.api.rabl: rabl has performance-issues with
# extend/partials (@see https://github.com/nesquena/rabl/issues/500)
# which drastically affects the performance of inline vs. partials: as the planning-elements are
# highly performance-critical, we need to live with this duplication until these issues are solved.
object @planning_element
attributes :id, :subject, :description, :author_id, :project_id, :parent_id, :status_id, :type_id, :priority_id

node :start_date, :if => lambda{|pe| pe.start_date.present?} { |pe| pe.start_date.to_formatted_s(:db) }
node :due_date, :if => lambda{|pe| pe.due_date.present?} {|pe| pe.due_date.to_formatted_s(:db) }

node :created_at, if: lambda{|pe| pe.created_at.present?} {|pe| pe.created_at.utc}
node :updated_at, if: lambda{|pe| pe.updated_at.present?} {|pe| pe.updated_at.utc}

node :destroyed, id: lambda{|pe| pe.destroyed?} {true}

child :project do
  attributes :id, :identifier, :name
end

node :parent, if: lambda{|pe| pe.parent.present?} do |pe|
  { id: pe.parent.id, subject: pe.parent.subject }
end

child :type do
  attributes :id, :name
end

child :status do
  attributes :id, :name
end

node :children, unless: lambda{|pe| pe.children.empty?} do |pe|
  pe.children.to_a.map { |wp| { id: wp.id, subject: wp.subject}}
end

child :author => :author do
  attributes :id, :name
end

node :responsible, if: lambda{|pe| pe.responsible.present?} do |pe|
  { id: pe.responsible.id, name: pe.responsible.name }
end

node :assigned_to, if: lambda{|pe| pe.assigned_to.present?} do |pe|
  { id: pe.responsible.id, name: pe.responsible.name }
end

node :custom_fields do
  partial "api/v2/custom_fields/values", :object => (locals[:object] || @planning_element).custom_values
end

node :journals, if: lambda{|pe| include_journals?} do |pe|
  pe.journals.map do |journal|
    partial "api/v2/planning_element_journals/journal", object: journal
  end
end



