# frozen_string_literal: true

RSpec.shared_examples "as an accessible inplace editor" do
  it "triggers edit mode on click" do
    page.document.synchronize(20) { scroll_to_element(field.display_element) }
    field.activate_edition
    expect(field).to be_editing
    field.cancel_by_escape
  end

  it "triggers edit mode on RETURN key" do
    if using_cuprite?
      page.document.synchronize(20) do
        element = field.display_element
        scroll_to_element(element)
        page.execute_script(<<~JS, element)
          arguments[0].dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", bubbles: true }))
        JS
      end
    else
      page.document.synchronize(20) { scroll_to_element(field.display_element) }
      field.display_element.send_keys(:return)
    end
    field.expect_active!
    field.cancel_by_escape
  end

  it "is focusable" do
    page.document.synchronize(20) { scroll_to_element(field.display_element) }

    tab_index = field.display_element["tabindex"]
    expect(tab_index).not_to be_nil
    expect(tab_index).not_to eq("-1")
  end
end

RSpec.shared_examples "as an auth aware field" do
  context "when is editable" do
    it_behaves_like "as an accessible inplace editor"
  end

  context "when user is authorized" do
    it "is editable" do
      expect(field).to be_editable
    end
  end

  context "when user is not authorized" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i(view_work_packages) })
    end

    it "is not editable" do
      expect(field).not_to be_editable
    end
  end
end

RSpec.shared_context "as a single validation point" do
  let(:other_field) { EditField.new page, :type }

  before do
    other_field.activate_edition
    field.activate_edition
    field.input_element.set ""
    field.submit_by_enter
  end

  after do
    field.cancel_by_escape
    other_field.cancel_by_escape
  end
end

RSpec.shared_context "as a required field" do
  before do
    field.activate_edition
    field.input_element.set ""
    field.submit_by_enter
  end

  after do
    field.cancel_by_escape
  end
end

RSpec.shared_examples "a cancellable field" do
  shared_examples "cancelling properly" do
    it "reverts to read state and keeps its focus" do
      expect(field).not_to be_editing
      field.expect_state_text(work_package.send(property_name))

      page.document.synchronize do
        active_class_name = page.evaluate_script("document.activeElement.className").to_s
        unless active_class_name.include?(field.display_selector[1..])
          active_element = page.evaluate_script("document.activeElement.outerHTML")
          raise Capybara::ExpectationNotMet,
                "Expected focus to return to the display field, but active element was #{active_element}"
        end
      end
    end
  end

  context "for escape" do
    before do
      field.activate!
      page.document.synchronize do
        unless field.input_element == page.evaluate_script("document.activeElement")
          raise Capybara::ExpectationNotMet, "Expected the editor to receive focus"
        end
      end
      field.cancel_by_escape
    end

    it_behaves_like "cancelling properly"
  end
end

RSpec.shared_examples "a workpackage autocomplete field" do
  let!(:wp2) { create(:work_package, project:, subject: "AutoFoo") }

  it "autocompletes the other work package" do
    field.activate!
    field.clear
    field.type(" ##{wp2.id}")
    expect(page).to have_css(".mention-list-item", text: wp2.to_s.strip)
  end
end

RSpec.shared_examples "a principal autocomplete field" do
  let(:role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages]) }
  let!(:user) do
    create(:user,
           member_with_roles: { project => role },
           firstname: "John")
  end
  let!(:mentioned_user) do
    create(:user,
           member_with_roles: { project => role },
           firstname: "Laura",
           lastname: "Foobar")
  end
  let!(:mentioned_group) do
    create(:group, lastname: "Laudators", member_with_roles: { project => role })
  end

  shared_examples "principal autocomplete on field" do
    before do
      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it "autocompletes links to user profiles" do
      field.activate!
      field.clear with_backspace: true
      field.ckeditor.click_and_type_slowly " @"
      wait_for_network_idle
      expect(page).to have_css(".mention-list-item", wait: 20)
      field.ckeditor.type_slowly "lau"
      wait_for_network_idle
      expect(page).to have_css(".mention-list-item", text: mentioned_user.name, wait: 20)
      expect(page).to have_css(".mention-list-item", text: mentioned_group.name)
      expect(page).to have_no_css(".mention-list-item", text: user.name)

      # Close the autocompleter
      field.input_element.send_keys :escape
      field.ckeditor.clear
      expect(page).to have_no_css(".mention-list-item")

      field.ckeditor.type_slowly "@"
      wait_for_network_idle
      expect(page).to have_css(".mention-list-item", wait: 20)
      field.ckeditor.type_slowly "Laura"
      wait_for_network_idle
      expect(page).to have_css(".mention-list-item", text: mentioned_user.name, wait: 20)
      expect(page).to have_no_css(".mention-list-item", text: mentioned_group.name)
      expect(page).to have_no_css(".mention-list-item", text: user.name)
    end
  end

  context "with the project page" do
    let(:wp_page) { Pages::SplitWorkPackage.new(work_package, project) }

    it_behaves_like "principal autocomplete on field"
  end

  context "without the project page" do
    let(:wp_page) { Pages::SplitWorkPackage.new(work_package) }

    it_behaves_like "principal autocomplete on field"
  end
end

RSpec.shared_examples "not a principal autocomplete field" do
  let(:role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages]) }
  let!(:user) do
    create(:user,
           member_with_roles: { project => role },
           firstname: "John")
  end
  let!(:mentioned_user) do
    create(:user,
           member_with_roles: { project => role },
           firstname: "Laura",
           lastname: "Foobar")
  end
  let!(:mentioned_group) do
    create(:group, lastname: "Laudators", member_with_roles: { project => role })
  end

  shared_examples "not principal autocomplete on field" do
    before do
      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it "does not autocompletes links to user profiles" do
      field.activate!
      field.clear with_backspace: true
      field.input_element.send_keys(" @lau")
      sleep 2
      expect(page).to have_no_css(".mention-list-item")
    end
  end

  context "with the project page" do
    let(:wp_page) { Pages::SplitWorkPackage.new(work_package, project) }

    it_behaves_like "not principal autocomplete on field"
  end

  context "without the project page" do
    let(:wp_page) { Pages::SplitWorkPackage.new(work_package) }

    it_behaves_like "not principal autocomplete on field"
  end
end
