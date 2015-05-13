shared_examples 'an accessible inplace editor' do
  let(:trigger_link) { field.find('a.inplace-editing--trigger-link') }
  it 'triggers edit mode on click' do
    field.click
    expect_editable
  end

  it 'triggers edit mode on RETURN key' do
    trigger_link.native.send_keys(:return)
    expect_editable
  end

  it 'is focusable' do
    tab_index = trigger_link['tabindex']
    expect(tab_index).to_not be_nil
    expect(tab_index).to_not eq('-1')
  end

  def expect_editable
    expect(field.find('.inplace-edit--write')).to be_visible
  end
end

shared_examples 'having a single validation point' do
  it 'triggers validation for all inputs'
end

shared_examples 'a required field' do
  it 'displays a required validation'
end

shared_examples 'an ESC-aware field' do
  it 'reverts to read state'
  it 'keeps old content'
  it 'focuses the trigger link'
end