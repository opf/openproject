require 'spec_helper'

describe 'Work Package table relations', js: true do
  let(:user) { FactoryBot.create :admin }

  let(:type) { FactoryBot.create(:type) }
  let(:type2) { FactoryBot.create(:type) }
  let(:project) { FactoryBot.create(:project, types: [type, type2]) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:relations) { ::Components::WorkPackages::Relations.new(relations) }
  let(:columns) { ::Components::WorkPackages::Columns.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }

  let!(:wp_from) { FactoryBot.create(:work_package, project: project, type: type2) }
  let!(:wp_to) { FactoryBot.create(:work_package, project: project, type: type) }
  let!(:wp_to2) { FactoryBot.create(:work_package, project: project, type: type) }

  let!(:relation) do
    FactoryBot.create(:relation,
                       from: wp_from,
                       to: wp_to,
                       relation_type: Relation::TYPE_FOLLOWS)
  end
  let!(:relation2) do
    FactoryBot.create(:relation,
                       from: wp_from,
                       to: wp_to2,
                       relation_type: Relation::TYPE_FOLLOWS)
  end
  let!(:query) do
    query              = FactoryBot.build(:query, user: user, project: project)
    query.column_names = ['subject']
    query.filters.clear

    query.save!
    query
  end

  let(:type_column_id) { "relationsToType#{type.id}" }
  let(:type_column_follows) { 'relationsOfTypeFollows' }
  let(:relation_columns_allowed) { true }

  before do
    # There does not seem to appear a way to generate a valid token
    # for testing purposes
    if relation_columns_allowed
      with_enterprise_token :work_package_query_relation_columns
    end

    login_as(user)
  end

  describe 'with relation columns allowed by the enterprise token' do
    it 'displays expandable relation columns' do
      # Now visiting the query for category
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(wp_from, wp_to, wp_to2)

      columns.add("Relations to #{type.name}")
      columns.add("follows relations")

      wp_from_row = wp_table.row(wp_from)
      wp_from_to = wp_table.row(wp_to)

      # Expect count for wp_from in both columns to be one
      expect(wp_from_row).to have_selector(".#{type_column_id} .wp-table--relation-count", text: '2')
      expect(wp_from_row).to have_selector(".#{type_column_follows} .wp-table--relation-count", text: '2')

      # Expect count for wp_to in both columns to be not rendered
      expect(wp_from_to).to have_no_selector(".#{type_column_id} .wp-table--relation-count")
      expect(wp_from_to).to have_no_selector(".#{type_column_follows} .wp-table--relation-count")

      # Expand first column
      wp_from_row.find(".#{type_column_id} .wp-table--relation-indicator").click
      expect(page).to have_selector(".__relations-expanded-from-#{wp_from.id}", count: 2)
      related_row = page.first(".__relations-expanded-from-#{wp_from.id}")
      expect(related_row).to have_selector('td.wp-table--relation-cell-td', text: "Precedes")

      # Collapse
      wp_from_row.find(".#{type_column_id} .wp-table--relation-indicator").click
      expect(page).to have_no_selector(".__relations-expanded-from-#{wp_from.id}")

      # Expand second column
      wp_from_row.find(".#{type_column_follows} .wp-table--relation-indicator").click
      expect(page).to have_selector(".__relations-expanded-from-#{wp_from.id}", count: 2)
      related_row = page.first(".__relations-expanded-from-#{wp_from.id}")
      expect(related_row).to have_selector('.wp-table--relation-cell-td', text: wp_to.type)

      # Open Timeline
      # Should be initially closed
      wp_timeline.expect_timeline!(open: false)

      # Enable timeline
      wp_timeline.toggle_timeline
      wp_timeline.expect_timeline!(open: true)

      # 3 WPs + 2 expanded relations
      wp_timeline.expect_row_count(5)

      # Collapse
      wp_from_row.find(".#{type_column_follows} .wp-table--relation-indicator").click
      expect(page).to have_no_selector(".__relations-expanded-from-#{wp_from.id}")

      wp_timeline.expect_row_count(3)
    end
  end

  describe 'with relation columns disallowed by the enterprise token' do
    let(:relation_columns_allowed) { false }

    it 'has no relation columns available for selection' do
      # Now visiting the query for category
      wp_table.visit_query(query)

      columns.expect_column_not_available 'follows relations'
      columns.expect_column_not_available "Relations to #{type.name}"
    end
  end
end
