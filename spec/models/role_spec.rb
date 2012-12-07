require 'spec_helper'

describe Role do
  describe '#by_permission' do
    it "returns roles with given permission" do
      edit_project_role = FactoryGirl.create :role, :permissions => [:edit_project]
          
      expect( Role.by_permission(:edit_project) ).to eq [edit_project_role]
      expect( Role.by_permission(:some_other)   ).to eq []
    end
  end
end
