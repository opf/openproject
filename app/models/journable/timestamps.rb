#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module Journable::Timestamps
  extend ActiveSupport::Concern

  class_methods do

    # Allows to query historic data of journables.
    #
    # For example, to check which work packages were assigned to a
    # specific user one year ago, run:
    #
    #     WorkPackage.where(assigned_to_id: 123).at_timestamp(1.year.ago)
    #
    def at_timestamp(timestamp)
      relation = self.all
      relation = Journable::HistoricActiveRecordRelation.new(relation, timestamp:)
      return relation
    end

  end

  # Instantiates a journable with historic data from the given timestap.
  #
  #     WorkPackage.find(1).at_timestamp(1.year.ago)
  #
  def at_timestamp(timestamp)
    if journal = self.journals.at_timestamp(timestamp).first
      attributes = journal.data.attributes.merge({
        "id" => self.id,
        "created_at" => self.created_at,
        "updated_at" => journal.updated_at,
        "timestamp" => timestamp,
        "position" => (self.position if self.respond_to? :position)
      })
      journable = self.class.instantiate(attributes)
      journable.readonly!
      return journable
    end
  end

  def historic?
    attributes["timestamp"].present?
  end
  def historical?
    historic?
  end

  # Rollback a journable record to a historic state of that record.
  #
  #     WorkPackage.find(2).at_timestamp(1.year.ago).rollback!
  #
  def rollback!
    raise ActiveRecord::RecordNotSaved, "This is no historic data. You can only revert to historic data." unless historic?
    self.class.find(id).update! self.attributes.except("id", "timestamp")
  end

end