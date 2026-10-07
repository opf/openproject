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

  def render_group(context: editor_context, **)
    render_inline(described_class.new(group:, context:, ee_available: true, first: true, last: true, **))
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

  it "hosts no list for a query group" do
    group.merge!(type: :query, attributes: [], query: "{}")
    render_group

    expect(page).to have_no_css("[data-controller~='sortable-lists--list']")
  end

  it "is neither item nor list while temporary" do
    group.merge!(id: nil, temporary: true, attributes: [])
    render_group(edit_mode: true)

    expect(page).to have_no_css("[data-controller~='sortable-lists--item'], [data-controller~='sortable-lists--list']")
  end

  it "renders no sortable data when readonly" do
    render_group(context: editor_context(readonly: true))

    expect(page).to have_no_css("[data-controller*='sortable-lists']")
    expect(page).to have_no_button(accessible_name: "Drag to reorder")
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
    let(:group) { { key: "details", name: "Details", type: :attribute, attributes: [], query: nil } }

    it "shows the drag hint in editable mode" do
      render_inline(described_class.new(group:, context: editor_context, ee_available: true, first: true, last: true))

      expect(page).to have_text("Drag attributes here")
    end

    it "omits the drag hint when readonly", :aggregate_failures do
      render_inline(described_class.new(group:, context: editor_context(readonly: true), ee_available: true,
                                        first: true, last: true))

      expect(page).to have_no_text("Drag attributes here")
      expect(page).to have_text("Details")
    end
  end
end
