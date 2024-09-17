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
require "spec_helper"

RSpec.describe "DB and ActiveRecord constraints" do # rubocop:disable RSpec/DescribeClass
  def self.has_max_length_validator?(model)
    max_length_validators(model).any?
  end

  def self.max_length_validators(model)
    model.validators.filter do |validator|
      validator.is_a?(ActiveRecord::Validations::LengthValidator) \
      && validator.options.has_key?(:maximum) \
      && model.columns_hash.has_key?(validator.attributes.first.to_s)
    end
  end

  def self.db_maximum_length(table_name, column_name)
    query = ActiveRecord::Base.sanitize_sql(
      [
        "SELECT character_maximum_length " \
        "FROM information_schema.columns " \
        "WHERE table_name = :table_name and column_name = :column_name",
        { table_name:, column_name: }
      ]
    )
    rows = ActiveRecord::Base.connection.execute(query)
    rows.first["character_maximum_length"]
  end

  ApplicationRecord.descendants
    .filter(&:table_exists?)
    .filter { |model| has_max_length_validator?(model) }
    .each do |model|
      describe "#{model} (table name: #{model.table_name})" do
        max_length_validators(model).each do |validator|
          attribute = validator.attributes.first
          model_max_length = validator.options[:maximum]
          db_max_length = db_maximum_length(model.table_name, attribute)
          if db_max_length
            db_field = "#{model.table_name}.#{attribute}"
            specify "max length of #{attribute.inspect} is #{model_max_length} for database field #{db_field}" do
              expect(db_max_length).to eq(model_max_length),
                                       "database maximum length of #{db_field} is #{db_max_length}, " \
                                       "should be #{model_max_length} like the model or removed"
            end
          end
        end
      end
    end
end
