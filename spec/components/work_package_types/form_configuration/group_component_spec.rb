# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GroupComponent, type: :component do
  let(:variant) { create(:type).default_variant }
  let(:record) { create(:form_configuration_group, form_configuration: variant.form_configuration, label: "Details") }
  let(:membership) do
    create(:form_configuration_attribute, form_configuration: variant.form_configuration, group: record, position: 1,
                                          attribute_key: "assignee")
  end
  let(:group) do
    {
      id: record.id,
      key: "details",
      name: "Details",
      type: :attribute,
      attributes: [
        { id: membership.id, key: "assignee", is_cf: false, required_globally: false, required_for_variant: false,
          translation: "Assignee", field_format_label: "Built-in field" }
      ],
      query: nil
    }
  end

  def editor_context(readonly: false, exclusions: nil)
    WorkPackageTypes::FormConfiguration::EditorContext.for_variant(variant, scope_project: nil).tap do |context|
      allow(context).to receive_messages(readonly?: readonly, exclusions:)
    end
  end

  def render_group(context: editor_context, first: true, last: true, **)
    render_inline(described_class.new(group:, context:, ee_available: true, first:, last:, **))
  end

  it "is a sortable group item keyed by its record", :aggregate_failures do
    render_group

    expect(page).to have_sortable_item(record, type: "group", label: "Details")
    expect(page).to have_css("##{described_class.wrapper_key}-#{record.id}")
    expect(page).to have_no_element("data-sortable-lists--item-mobility-value": true)
  end

  it "stays a fixed sortable item while its editor is open", :aggregate_failures do
    render_group(edit_mode: true)

    expect(page).to have_sortable_item(record, type: "group", label: "Details")
    expect(page).to have_element("data-sortable-lists--item-id-value": record.id.to_s,
                                 "data-sortable-lists--item-mobility-value": "fixed")
  end

  it "keeps the key data of a row without a record but makes it no item", :aggregate_failures do
    group[:attributes].first[:id] = nil
    render_group

    expect(page).to have_element("data-attr-key": "assignee", "data-attr-translation": "Assignee",
                                 "data-attr-is-cf": "false")
    expect(page).to have_no_element("data-sortable-lists--item-type-value": "attribute")
  end

  it "hosts its attributes in a list named after the group", :aggregate_failures do
    render_group

    expect(page).to have_css("[data-controller~='sortable-lists--list']", count: 1) do |list|
      expect(list["data-sortable-lists--list-type-value"]).to eq("attribute")
      expect(list["data-sortable-lists--list-accepted-type-value"]).to eq("attribute")
      expect(list["data-sortable-lists--list-id-value"]).to eq(record.id.to_s)
      expect(list["data-sortable-lists--list-name-value"]).to eq("Details")
      expect(list["data-sortable-lists--item-target"]).to eq("preview")
    end
    expect(page).to have_css("[data-controller~='sortable-lists--list'] > ul > li", count: 1)
    expect(page).to have_sortable_item(membership, type: "attribute", label: "Assignee")
  end

  it "marks one drag handle per item", :aggregate_failures do
    render_group

    expect(page).to have_button(accessible_name: "Drag to reorder", count: 2) do |handle|
      handle["data-sortable-lists--item-target"] == "handle"
    end
  end

  it "gives a query group the edit-query menu in its item" do
    group.merge!(type: :query, attributes: [], query: "{}")
    render_group

    expect(page).to have_css(".Box-row") do |row|
      expect(row).to have_button(accessible_name: "Row actions")
      expect(row).to have_selector(:menuitem, "Edit query", visible: :all)
    end
  end

  describe "the query row's menu gating" do
    before { group.merge!(type: :query, attributes: [], query: "{}") }

    it "is absent when readonly" do
      render_group(context: editor_context(readonly: true))

      expect(page).to have_no_button(accessible_name: "Row actions")
    end

    it "is absent without Enterprise edition" do
      render_inline(described_class.new(group:, context: editor_context, ee_available: false, first: true, last: true))

      expect(page).to have_no_button(accessible_name: "Row actions")
    end
  end

  describe "the attribute row menu" do
    it "offers Delete in the editor", :aggregate_failures do
      render_group

      expect(page).to have_css("li.Box-row") do |row|
        expect(row).to have_button(accessible_name: "Row actions")
        expect(row).to have_selector(:menuitem, "Delete", visible: :all)
      end
    end

    context "when readonly" do
      it "offers the required toggle on a custom field", :aggregate_failures do
        group[:attributes] = [
          { id: nil, key: "custom_field_5", is_cf: true, required_globally: false, required_for_variant: false,
            translation: "Alt description", field_format_label: "Text" }
        ]
        render_group(context: editor_context(readonly: true))

        expect(page).to have_css("li.Box-row") do |row|
          expect(row).to have_button(accessible_name: "Row actions")
          expect(row).to have_selector(:menuitem, "Require in this type", visible: :all)
        end
      end

      it "is absent on a built-in attribute" do
        render_group(context: editor_context(readonly: true))

        expect(page).to have_no_button(accessible_name: "Row actions")
      end
    end
  end

  it "hosts no list for a query group" do
    group.merge!(type: :query, attributes: [], query: "{}")
    render_group

    expect(page).to have_no_css("[data-controller~='sortable-lists--list']")
  end

  it "is neither item nor list while temporary, and shows only the editor", :aggregate_failures do
    group.merge!(id: nil, name: "", temporary: true, attributes: [])
    render_group(edit_mode: true)

    expect(page).to have_no_css("[data-controller~='sortable-lists--item'], [data-controller~='sortable-lists--list']")
    expect(page).to have_heading("New section", level: 3, visible: :all)
    expect(page).to have_field("Section name")
    expect(page).to have_no_text("Drag attributes here")
    expect(page).to have_no_text("No attributes in this section")
  end

  it "renders no sortable data when readonly" do
    render_group(context: editor_context(readonly: true))

    expect(page).to have_no_css("[data-controller*='sortable-lists']")
    expect(page).to have_no_button(accessible_name: "Drag to reorder")
  end

  it "renders its name as a level 3 heading of a Border Box list", :aggregate_failures do
    render_group

    expect(page).to have_heading("Details")
    expect(page).to have_heading("Details", level: 3)
    expect(page).to have_css(".op-border-box-list[data-controller~='sortable-lists--list']")
  end

  it "places the group menu before any row menu" do
    render_group

    expect(page).to have_xpath("(//action-menu)[1][ancestor::*[contains(@class, 'Box-header')]]", visible: :all)
  end

  it "offers the four shared move items for a group among others" do
    render_group(first: false, last: false)

    expect(page).to have_css(".Box-header [data-sortable-lists--item-target='moveItem']", count: 4, visible: :all)
  end

  it "offers no group move items for the only group" do
    render_group(first: true, last: true)

    expect(page).to have_no_css(".Box-header [data-sortable-lists--item-target='moveItem']", visible: :all)
  end

  it "offers no row move items for the only attribute" do
    render_group

    expect(page).to have_no_css(".Box-row [data-sortable-lists--item-target='moveItem']", visible: :all)
  end

  context "with two attributes" do
    before do
      group[:attributes] << { id: nil, key: "responsible", is_cf: false, required_globally: false,
                              required_for_variant: false, translation: "Accountable",
                              field_format_label: "Built-in field" }
    end

    it "offers the four shared move items per row" do
      render_group

      expect(page).to have_css(".Box-row [data-sortable-lists--item-target='moveItem']", count: 8, visible: :all)
    end
  end

  describe "the rename editor" do
    it "replaces the header with the title form", :aggregate_failures do
      render_group(edit_mode: true)

      expect(page).to have_field("Section name", with: "Details")
      expect(page).to have_button("Save")
      expect(page).to have_link("Cancel")
      expect(page).to have_heading("Details", level: 3, visible: :all)
      expect(page.find(".Box-header")).to have_no_button(accessible_name: "Drag to reorder")
      expect(page).to have_no_button(accessible_name: "Section actions")
      expect(page).to have_element("data-edit-mode": "true")
    end

    it "carries the group type and omits an absent query", :aggregate_failures do
      render_group(edit_mode: true)

      expect(page).to have_field("group[group_type]", type: :hidden, with: "attribute")
      expect(page).to have_no_field("group[query]", type: :hidden)
    end

    it "carries the query of a query group" do
      group.merge!(type: :query, attributes: [], query: '{"f":[]}')
      render_group(edit_mode: true)

      expect(page).to have_field("group[query]", type: :hidden, with: '{"f":[]}')
    end

    it "shows a rejected name's message without an attribute prefix", :aggregate_failures do
      form_model = WorkPackageTypes::FormConfiguration::GroupFormModel
                     .from_group(group, name: "", validation_message: "Group name can't be blank.")
      render_group(edit_mode: true, form_model:)

      expect(page).to have_text("Group name can't be blank.")
      expect(page).to have_no_text("Name Group name")
      expect(page).to have_field("Section name", with: "")
    end
  end

  it_behaves_like "no legacy drag-and-drop wiring" do
    let(:rendered_component) { render_group }
  end

  it "renders handles and per-row drag data in editable mode", :aggregate_failures do
    render_inline(described_class.new(group:, context: editor_context, ee_available: true, first: true, last: true))

    expect(page).to have_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_test_selector("type-form-configuration-attribute-handle-assignee")
  end

  it "renders the update-query URL for the group as data", :aggregate_failures do
    render_inline(described_class.new(group:, context: editor_context, ee_available: true, first: true, last: true))

    expect(page).to have_element "data-group-key": "details" do |wrapper|
      expect(wrapper["data-update-query-url"])
        .to end_with("/forms/#{variant.form_configuration_id}/group/update_query?key=details")
    end
  end

  context "with HTML-sensitive characters in the key" do
    let(:key) { 'b) > 10.000 "<Nutzende>"' }
    let(:group) { { key:, name: key, type: :attribute, attributes: [], query: nil } }

    it "escapes the key inside the data attributes", :aggregate_failures do
      render_inline(described_class.new(group:, context: editor_context, ee_available: true, first: true, last: true))

      expect(page).to have_element "data-group-key": key do |wrapper|
        expect(wrapper["data-update-query-url"]).to end_with("?key=b%29+%3E+10.000+%22%3CNutzende%3E%22")
      end
    end

    it "derives DOM ids without whitespace from the key", :aggregate_failures do
      render_inline(described_class.new(group:, context: editor_context(readonly: true), ee_available: true,
                                        first: true, last: true))

      box_ids = page.all(".op-border-box-list, .op-border-box-list [id]", visible: :all).filter_map { it[:id] }
      expect(box_ids).not_to be_empty
      expect(box_ids).to all(match(/\A\S+\z/))
    end
  end

  it "renders no handles, menus, or drag data when readonly", :aggregate_failures do
    render_inline(described_class.new(group:, context: editor_context(readonly: true), ee_available: true,
                                      first: true, last: true))

    expect(page).to have_no_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_no_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_no_test_selector("type-form-configuration-attribute-actions-assignee")
    expect(page).to have_text("Details")
    expect(page).to have_text("Assignee")
  end

  context "with an empty group" do
    let(:group) { { id: record.id, key: "details", name: "Details", type: :attribute, attributes: [], query: nil } }

    it "shows the empty state with a drop overlay in editable mode", :aggregate_failures do
      render_group

      expect(page).to have_heading("No attributes in this section")
      expect(page).to have_text("Drag attributes here")
      expect(page).to have_css("[aria-hidden='true']", text: "Drop attribute here", visible: :all)
      expect(page).to have_css("[data-controller~='border-box-list'] [data-controller~='sortable-lists--list']")
    end

    it "shows no empty state when readonly", :aggregate_failures do
      render_group(context: editor_context(readonly: true))

      expect(page).to have_no_text("No attributes in this section")
      expect(page).to have_no_text("Drag attributes here")
      expect(page).to have_heading("Details")
    end
  end
end
