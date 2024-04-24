require "spec_helper"

RSpec.describe "Work Package table relations", :js, with_ee: %i[work_package_query_relation_columns] do
  let(:user) { create(:admin) }

  let(:type) { create(:type) }
  let(:type2) { create(:type) }
  let(:project) { create(:project, types: [type, type2]) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:relations) { Components::WorkPackages::Relations.new(relations) }
  let(:columns) { Components::WorkPackages::Columns.new }

  let!(:wp_from) { create(:work_package, project:, type: type2) }
  let!(:wp_to) { create(:work_package, project:, type:) }
  let!(:wp_to2) { create(:work_package, project:, type:) }

  let!(:relation) do
    create(:relation,
           from: wp_from,
           to: wp_to,
           relation_type: Relation::TYPE_FOLLOWS)
  end
  let!(:relation2) do
    create(:relation,
           from: wp_from,
           to: wp_to2,
           relation_type: Relation::TYPE_FOLLOWS)
  end
  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject"]
    query.filters.clear

    query.save!
    query
  end

  let(:type_column_id) { "relationsToType#{type.id}" }
  let(:type_column_follows) { "relationsOfTypeFollows" }

  before do
    login_as(user)
  end

  describe "with relation columns allowed by the enterprise token" do
    it "displays expandable relation columns" do
      # Now visiting the query for category
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(wp_from, wp_to, wp_to2)

      columns.add(type.name)
      columns.add("Follows")

      wp_from_row = wp_table.row(wp_from)
      wp_from_to = wp_table.row(wp_to)

      # Expect count for wp_from in both columns to be one
      expect(wp_from_row).to have_css(".#{type_column_id} .wp-table--relation-count", text: "2")
      expect(wp_from_row).to have_css(".#{type_column_follows} .wp-table--relation-count", text: "2")

      # Expect count for wp_to in both columns to be not rendered
      expect(wp_from_to).to have_no_css(".#{type_column_id} .wp-table--relation-count")
      expect(wp_from_to).to have_no_css(".#{type_column_follows} .wp-table--relation-count")

      # Expand first column
      wp_from_row.find(".#{type_column_id} .wp-table--relation-indicator").click
      expect(page).to have_css(".__relations-expanded-from-#{wp_from.id}", count: 2)
      related_row = page.first(".__relations-expanded-from-#{wp_from.id}")
      expect(related_row).to have_css("td.wp-table--relation-cell-td", text: "Precedes")

      # Collapse
      wp_from_row.find(".#{type_column_id} .wp-table--relation-indicator").click
      expect(page).to have_no_css(".__relations-expanded-from-#{wp_from.id}")

      # Expand second column
      wp_from_row.find(".#{type_column_follows} .wp-table--relation-indicator").click
      expect(page).to have_css(".__relations-expanded-from-#{wp_from.id}", count: 2)
      related_row = page.first(".__relations-expanded-from-#{wp_from.id}")
      expect(related_row).to have_css(".wp-table--relation-cell-td", text: wp_to.type)
    end
  end

  describe "with relation columns disallowed by the enterprise token", with_ee: false do
    it "has no relation columns available for selection" do
      # Now visiting the query for category
      wp_table.visit_query(query)

      columns.expect_column_not_available "follows relations"
      columns.expect_column_not_available "Relations to #{type.name}"
    end
  end
end
