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

  describe "#list_join_table" do
    let!(:work_package) { create(:work_package) }
    let!(:field_a) { create(:list_wp_custom_field, name: "Field A", possible_values: ["Own value"]) }
    let!(:field_b) { create(:list_wp_custom_field, name: "Field B", possible_values: ["Other field's value"]) }
    let(:item_a) { field_a.possible_values.first }
    let(:item_b) { field_b.possible_values.first }

    def joined_label_for(field)
      klass = Class.new(CostQuery::GroupBy::CustomFieldEntries)
      klass.prepare(field, "TestCustomField#{field.id}")
      join_sql = klass.table_joins.first.first

      # Not squished: join_sql carries `--` line comments from list_join_table, which
      # would swallow the rest of the query once collapsed onto one line.
      sql = <<~SQL # rubocop:disable Rails/SquishedSQLHeredocs
        WITH entries AS (SELECT #{work_package.id} AS entity_id)
        SELECT #{klass.db_field}.value AS label
        FROM entries
        #{join_sql}
      SQL

      ActiveRecord::Base.connection.select_value(sql)
    end

    it "resolves a value to its own custom field's item" do
      ActiveRecord::Base.connection.execute(<<~SQL.squish)
        INSERT INTO custom_values (customized_type, customized_id, custom_field_id, value)
        VALUES ('WorkPackage', #{work_package.id}, #{field_a.id}, '#{item_a.id}')
      SQL

      expect(joined_label_for(field_a)).to eq(item_a.label)
    end

    it "does not resolve a stale value that happens to match another field's item id" do
      ActiveRecord::Base.connection.execute(<<~SQL.squish)
        INSERT INTO custom_values (customized_type, customized_id, custom_field_id, value)
        VALUES ('WorkPackage', #{work_package.id}, #{field_a.id}, '#{item_b.id}')
      SQL

      expect(joined_label_for(field_a)).to be_nil
    end
  end
end
