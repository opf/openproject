shared_examples 'an accessible inplace editor' do
  it 'triggers edit mode on click' do
    field.activate_edition
    expect(field).to be_editing
    field.cancel_by_click
  end

  it 'triggers edit mode on RETURN key' do
    field.trigger_link.native.send_keys(:return)
    expect(field).to be_editing
    field.cancel_by_click
  end

  it 'is focusable' do
    tab_index = field.trigger_link['tabindex']
    expect(tab_index).to_not be_nil
    expect(tab_index).to_not eq('-1')
  end
end

shared_examples 'an auth aware field' do
  context 'when is editable' do
    it_behaves_like 'an accessible inplace editor'
  end

  context 'when user is authorized' do
    it 'is editable' do
      expect(field).to be_editable
    end
  end

  context 'when user is not authorized' do
    let(:user) {
      FactoryGirl.create(
        :user,
        member_in_project: project,
        member_through_role: FactoryGirl.build(
          :role,
          permissions: [:view_work_packages]
        )
      )
    }

    it 'is not editable' do
      expect { field.trigger_link }.to raise_error Capybara::ElementNotFound
    end
  end
end

shared_examples 'having a single validation point' do
  let(:other_field) { WorkPackageField.new page, :type }
  before do
    other_field.activate_edition
    field.activate_edition
    field.input_element.set ''
    field.submit_by_click
  end

  after do
    field.cancel_by_click
    other_field.cancel_by_click
  end

  it 'displays validation for all inputs' do
    expect(other_field.errors_element).to be_visible
    expect(other_field.errors_text).to eq "#{property_title} cannot be empty"
  end
end

shared_examples 'a required field' do
  before do
    field.activate_edition
    field.input_element.set ''
    field.submit_by_click
  end

  after do
    field.cancel_by_click
  end

  it 'displays a required validation' do
    expect(field.errors_element).to be_visible
    expect(field.errors_text).to eq "#{property_title} cannot be empty"
  end
end

shared_examples 'a cancellable field' do
  shared_examples 'cancelling properly' do
    it 'reverts to read state' do
      expect(field).to_not be_editing
    end

    it 'keeps old content' do
      expect(field.read_state_text).to eq work_package.send(property_name)
    end

    it 'focuses the trigger link' do
      active_class_name = page.evaluate_script('document.activeElement.className')
      trigger_link_focused = "a.#{active_class_name}" == field.trigger_link_selector

      expect(trigger_link_focused).to be_truthy
    end
  end

  context 'by click' do
    before do
      field.activate_edition
      field.cancel_by_click
    end

    it_behaves_like 'cancelling properly'
  end

  context 'by escape' do
    before do
      field.activate_edition
      field.cancel_by_escape
    end

    after do
      field.cancel_by_click
    end

    it_behaves_like 'cancelling properly'
  end
end
