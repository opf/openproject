require 'spec_helper'

describe MenuItem do
  describe 'validations' do
    let(:item) { FactoryGirl.build :menu_item }

    it 'requires a title' do
      item.title = nil
      item.should_not be_valid
      item.errors.should have_key :title
    end

    it 'requires a name' do
      item.name = nil
      item.should_not be_valid
      item.errors.should have_key :name
    end

    describe 'scoped uniqueness of title' do
      let!(:item) { FactoryGirl.create :menu_item }
      let(:another_item) { FactoryGirl.build :menu_item, title: item.title }
      let(:wiki_menu_item) { FactoryGirl.build :wiki_menu_item, title: item.title }

      it 'does not allow for duplicate titles' do
        another_item.should_not be_valid
        another_item.errors.should have_key :title
      end

      it 'allows for creating a menu item with the same title if it has a different type' do
        wiki_menu_item.should be_valid
      end
    end
  end

  context 'it should destroy' do
    let!(:menu_item) { FactoryGirl.create(:menu_item) }
    let!(:child_item) { FactoryGirl.create(:menu_item, parent_id: menu_item.id ) }

    example 'all children when deleting the parent' do
      menu_item.destroy
      MenuItem.exists?(child_item.id).should be_false
    end
  end
end
