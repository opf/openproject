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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
module BasicData
  class ModelSeeder < Seeder
    # The class of the model for creating records.
    class_attribute :model_class
    # The key under which the data is found in the seed file.
    class_attribute :seed_data_model_key
    # The names of the attributes used to lookup an existing model in an already
    # seeded database. Optional.
    class_attribute :attribute_names_for_lookups

    def seed_data!
      model_class.transaction do
        models_data.each do |model_data|
          model = model_class.create!(model_attributes(model_data))
          seed_data.store_reference(model_data["reference"], model)
        end
      end
    end

    def mapped_models_data
      models_data.each_with_object({}) do |model_data, models|
        models[model_data["reference"]] = model_attributes(model_data)
      end
    end

    def models_data
      Array(seed_data.lookup(seed_data_model_key))
    end

    def model_attributes(model_data)
      raise NotImplementedError
    end

    def applicable?
      model_class.none?
    end

    def lookup_existing_references
      return if attribute_names_for_lookups.blank?

      models_data.each do |model_data|
        lookup_attributes = model_attributes(model_data).slice(*attribute_names_for_lookups)
        if model = model_class.find_by(lookup_attributes)
          seed_data.store_reference(model_data["reference"], model)
        end
      end
    end

    def not_applicable_message
      "Skipping #{model_human_name} as there are already some configured"
    end

    def model_human_name
      seed_data_model_key.humanize(capitalize: false)
    end

    # Casts `'false'`, `'no'`, `''`, and `nil` into `false`, and return `true`
    # for other values.
    def true?(value)
      ActiveRecord::Type::Boolean.new.cast(value) || false
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
