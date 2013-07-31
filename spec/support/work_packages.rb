def become_admin
  let(:current_user) { FactoryGirl.create(:admin) }
end

def become_non_member(&block)
  let(:current_user) { FactoryGirl.create(:user) }

  before do
    projects = block ? instance_eval(&block) : [project]

    projects.each do |p|
      current_user.memberships.select {|m| m.project_id == p.id}.each(&:destroy)
    end
  end
end

def become_member_with_permissions(permissions)
  let(:current_user) { FactoryGirl.create(:user) }

  before do
    role = FactoryGirl.create(:role, :permissions => permissions)

    member = FactoryGirl.build(:member, :user => current_user, :project => project)
    member.roles = [role]
    member.save!
  end
end

def become_member_with_view_planning_element_permissions
  become_member_with_permissions [:view_planning_elements, :view_work_packages]
end
