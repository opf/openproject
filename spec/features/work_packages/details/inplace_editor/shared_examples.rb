shared_examples 'an accessible inplace editor' do
  it 'triggers edit mode on click' do
    field.activate_edition
    expect(field).to be_editable
  end

  it 'triggers edit mode on RETURN key' do
    field.trigger_link.native.send_keys(:return)
    expect(field).to be_editable
  end

  it 'is focusable' do
    tab_index = field.trigger_link['tabindex']
    expect(tab_index).to_not be_nil
    expect(tab_index).to_not eq('-1')
  end
end

shared_examples 'having a single validation point' do
  it 'triggers validation for all inputs'
end

shared_examples 'a required field' do
  before do
    field.activate_edition
    field.input_element.set ''
    field.submit_by_click
  end

  it 'displays a required validation' do
    expect(field.element.find('.inplace-edit--errors')).to be_visible
    expect(field.element.find('.inplace-edit--errors--text').text).to eq "#{property_title} cannot be empty"
  end
end

shared_examples 'a cancellable field' do
  shared_examples 'cancelling properly' do
    it 'reverts to read state' do
      expect(field).to_not be_editable
    end

    it 'keeps old content' do
      expect(field.read_state_text).to eq work_package.send(property_name)
    end

    it 'focuses the trigger link' do
      expect(page).to have_selector("#{field_selector} #{field.trigger_link_selector}:focus")
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

    it_behaves_like 'cancelling properly'
  end
end
