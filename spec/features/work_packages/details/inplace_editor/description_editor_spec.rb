require 'spec_helper'

describe 'description inplace editor' do
  context 'in read state' do
    it 'renders the correct HTML'

    context 'when is empty' do
      it 'renders a placeholder'
    end

    context 'when is editable' do
      it_behaves_like 'an accessible inplace editor'

      context 'when clicking on an anchor' do
        it 'navigates to the given url'
        it 'does not trigger editing'
      end
    end

    context 'when user is authorized' do
      it 'is editable'
    end

    context 'when user is not authorized' do
      it 'is not editable'
    end
  end

  context 'in edit state' do
    it 'renders a textarea'
    it 'renders formatting buttons'
    it 'renders a preview button'
    it 'has a correct value for the textarea'
    it 'displays the new HTML after save'
    it_behaves_like 'an ESC-aware field'
    it_behaves_like 'having a single validation point'
  end
end