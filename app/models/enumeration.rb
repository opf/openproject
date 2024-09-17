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

class Enumeration < ApplicationRecord
  include SubclassRegistry

  default_scope { order("#{Enumeration.table_name}.position ASC") }

  belongs_to :project, optional: true

  acts_as_list scope: 'type = \'#{type}\''
  acts_as_tree order: "position ASC"

  before_save :unmark_old_default_value, if: :became_default_value?
  before_destroy :check_integrity

  validates :name, presence: true
  validates :name,
            uniqueness: { scope: %i(type project_id),
                          case_sensitive: false }
  validates :name, length: { maximum: 256 }

  scope :shared, -> { where(project_id: nil) }
  scope :active, -> { where(active: true) }

  # let all child classes have Enumeration as it's model name
  # used to not having to create another route for every subclass of Enumeration
  def self.inherited(child)
    child.instance_eval do
      def model_name
        Enumeration.model_name
      end
    end
    super
  end

  def self.colored?
    false
  end

  def self.default
    # Creates a fake default scope so Enumeration.default will check
    # it's type.  STI subclasses will automatically add their own
    # types to the finder.
    if descends_from_active_record?
      where(is_default: true, type: "Enumeration").first
    else
      # STI classes are
      where(is_default: true).first
    end
  end

  # Destroys enumerations in a single transaction
  # It ensures, that the transactions can be safely transferred to each
  # entry's parent
  def self.bulk_destroy(entries)
    sorted_entries = sort_by_ancestor_last(entries)

    sorted_entries.each do |entry|
      entry.destroy(entry.parent)
    end
  end

  # Overloaded on concrete classes
  def option_name
    nil
  end

  def became_default_value?
    is_default? && is_default_changed?
  end

  def unmark_old_default_value
    Enumeration.where(type:).update_all(is_default: false)
  end

  # Overloaded on concrete classes
  def objects_count
    0
  end

  def in_use?
    objects_count != 0
  end

  def shared?
    parent_id.nil?
  end

  alias :destroy_without_reassign :destroy

  # Destroy the enumeration
  # If a enumeration is specified, objects are reassigned
  def destroy(reassign_to = nil)
    if reassign_to && reassign_to.is_a?(Enumeration)
      transfer_relations(reassign_to)
    end
    destroy_without_reassign
  end

  def <=>(other)
    position <=> other.position
  end

  def to_s; name end

  # Does the +new+ Hash override the previous Enumeration?
  def self.overriding_change?(new, previous)
    if same_active_state?(new["active"], previous.active) && same_custom_values?(new, previous)
      false
    else
      true
    end
  end

  # Does the +new+ Hash have the same custom values as the previous Enumeration?
  def self.same_custom_values?(new, previous)
    previous.custom_field_values.each do |custom_value|
      if new &&
         new["custom_field_values"] &&
         custom_value.value != new["custom_field_values"][custom_value.custom_field_id.to_s]
        return false
      end
    end

    true
  end

  # Are the new and previous fields equal?
  def self.same_active_state?(new, previous)
    new = new == "1"
    new == previous
  end

  # This is not a performant method.
  def self.sort_by_ancestor_last(entries)
    ancestor_relationships = entries.map { |entry| [entry, entry.ancestors] }

    ancestor_relationships.sort do |one, two|
      if one.last.include?(two.first)
        -1
      elsif two.last.include?(one.first)
        1
      else
        0
      end
    end.map(&:first)
  end

  private

  def check_integrity
    raise "Can't delete enumeration" if in_use?
  end
end

# Force load the subclasses in development mode
%w(time_entry_activity issue_priority).each do |enum_subclass|
  require enum_subclass
end
