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

RSpec.shared_examples_for "rewritten record" do |factory, attribute, format = Integer|
  let!(:model) do
    klass = FactoryBot.factories.find(factory).build_class
    all_attributes = other_attributes.merge(attribute => principal_id)
    all_attributes[:created_at] ||= "NOW()" if klass.column_names.include?("created_at")
    all_attributes[:updated_at] ||= "NOW()" if klass.column_names.include?("updated_at")

    inserted = ActiveRecord::Base.connection.select_one <<~SQL.squish
      INSERT INTO #{klass.table_name}
      (#{all_attributes.keys.join(', ')})
      VALUES
      (#{all_attributes.values.join(', ')})
      RETURNING id
    SQL

    klass.find(inserted["id"])
  end

  let(:other_attributes) do
    defined?(attributes) ? attributes : {}
  end

  def expected(user, format)
    if format == String
      user.id.to_s
    else
      user.id
    end
  end

  context "for #{factory}" do
    context "when #{attribute} is set to the replaced user" do
      let(:principal_id) { principal.id }

      before do
        service_call
        model.reload
      end

      it "replaces its value" do
        expect(model.send(attribute))
          .to eql expected(to_principal, format)
      end
    end

    context "when #{attribute} is set to a different user" do
      let(:principal_id) { other_user.id }

      before do
        service_call
        model.reload
      end

      it "keeps its value" do
        expect(model.send(attribute))
          .to eql expected(other_user, format)
      end
    end
  end
end
