# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CostQuery::CustomFieldMixin, :reporting_query_helper do
  minimal_query

  let!(:project) { create(:project_with_types) }
  let!(:user) { create(:admin) }

  describe "#default_join_table" do
    let!(:custom_field) do
      create(:wp_custom_field, :string, name: "Robert'); DROP TABLE Students;-- Roberts")
    end

    before do
      CostQuery::Cache.reset!
      CostQuery::Filter::CustomFieldEntries.all
    end

    after do
      CostQuery::Cache.reset!
      CostQuery::Filter::CustomFieldEntries.reset!
    end

    it "uses field.id in the SQL comment and does not include the field name" do
      query.filter custom_field.attribute_name, operator: "=", value: "test"
      sql = query.sql_statement.to_s

      expect(sql).to include("-- BEGIN Custom Field Join: cf_#{custom_field.id}")
      expect(sql).to include("-- END Custom Field Join: cf_#{custom_field.id}")
      expect(sql).not_to include("DROP TABLE students")
      expect(sql).to include("CAST(value AS varchar)")
    end
  end
end
