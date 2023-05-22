# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
module BasicData
  class ModelSeeder < Seeder
    class_attribute :model_class
    class_attribute :seed_data_model_key

    def seed_data!
      model_class.transaction do
        Array(seed_data.lookup(seed_data_model_key)).each do |model_data|
          model = model_class.create!(model_attributes(model_data))
          seed_data.store_reference(model_data['reference'], model)
        end
      end
    end

    def model_attributes(model_data)
      raise NotImplementedError
    end

    def applicable?
      model_class.none?
    end

    def not_applicable_message
      "Skipping #{model_human_name} as there are already some configured"
    end

    def model_human_name
      seed_data_model_key.humanize(capitalize: false)
    end

    protected

    def color_id(name)
      @color_ids_by_name ||= Color.pluck(:name, :id).to_h
      case name
      when Symbol
        seed_data.find_reference(name).id
      else
        @color_ids_by_name[name] or raise "Cannot find color #{name}"
      end
    end
  end
end
