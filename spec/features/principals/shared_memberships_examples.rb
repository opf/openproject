shared_context 'principal membership management context' do
  shared_let(:project) { FactoryBot.create :project, name: 'Project 1', identifier: 'project1' }
  shared_let(:project2) { FactoryBot.create :project, name: 'Project 2', identifier: 'project2' }

  shared_let(:manager)   { FactoryBot.create :role, name: 'Manager', permissions: %i[view_members manage_members] }
  shared_let(:developer) { FactoryBot.create :role, name: 'Developer' }
end

shared_examples 'principal membership management flows' do
  scenario 'handles role modification flow' do
    principal_page.visit!
    principal_page.open_projects_tab!

    principal_page.add_to_project! project.name, as: 'Manager'

    member = principal.memberships.where(project_id: project.id).first
    principal_page.edit_roles!(member, %w(Manager Developer))

    # Modify roles
    principal_page.expect_project(project.name)
    principal_page.expect_roles(project.name, %w(Manager Developer))

    principal_page.expect_no_membership(project2.name)

    # Remove all roles
    principal_page.expect_project(project.name)
    principal_page.edit_roles!(member, %w())

    expect(page).to have_selector('.flash.error', text: 'Roles need to be assigned.')

    # Remove the user from the project
    principal_page.remove_from_project!(project.name)
    principal_page.expect_no_membership(project.name)

    # Re-add the user
    principal_page.add_to_project! project.name, as: %w(Manager Developer)

    principal_page.expect_project(project.name)
    principal_page.expect_roles(project.name, %w(Manager Developer))
  end
end

shared_examples 'global user principal membership management flows' do |permission|
  context 'as global user' do
    shared_let(:global_user) { FactoryBot.create :user, global_permission: permission }
    current_user { global_user }

    context 'when the user is member in the projects' do
      it_behaves_like 'principal membership management flows' do
      before do
          project.add_member global_user, [manager]
          project.save!

          project2.add_member global_user, [manager]
          project2.save!
        end
      end
    end

    context 'when the user cannot see the two projects' do
      it 'does not show them' do
        principal_page.visit!
        principal_page.open_projects_tab!

        expect(page).to have_no_selector('#membership_project_id option', text: project.name, visible: :all)
        expect(page).to have_no_selector('#membership_project_id option', text: project2.name, visible: :all)
      end

      it 'does not show the membership' do
        project.add_member principal, [developer]
        project.save!

        principal_page.visit!
        principal_page.open_projects_tab!

        expect(page).to have_no_selector('tr.member')
        expect(page).to have_text 'There is currently nothing to display.'
        expect(page).to have_no_text project2.name
        expect(page).to have_no_text project2.name
      end
    end
  end

  context 'as user without global permission' do
    current_user { FactoryBot.create :user }

    it 'returns an error' do
      principal_page.visit!
      expect(page).to have_text 'You are not authorized to access this page.'
      expect(page).to have_no_text principal.name
    end
  end
end