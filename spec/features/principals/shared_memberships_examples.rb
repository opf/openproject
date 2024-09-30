RSpec.shared_context "principal membership management context" do
  shared_let(:project) do
    create(:project,
           name: "Project 1",
           identifier: "project1")
  end
  shared_let(:project2) { create(:project, name: "Project 2", identifier: "project2") }

  shared_let(:manager)   { create(:project_role, name: "Manager", permissions: %i[view_members manage_members]) }
  shared_let(:developer) { create(:project_role, name: "Developer") }
end

RSpec.shared_examples "principal membership management flows" do
  it "handles role modification flow" do
    principal_page.visit!
    principal_page.open_projects_tab!

    principal_page.add_to_project! project.name, as: "Manager"

    member = principal.memberships.where(project_id: project.id).first
    principal_page.edit_roles!(member, %w(Manager Developer))

    # Modify roles
    principal_page.expect_project(project.name)
    principal_page.expect_roles(project.name, %w(Manager Developer))

    principal_page.expect_no_membership(project2.name)

    # Remove all roles
    principal_page.expect_project(project.name)
    principal_page.edit_roles!(member, %w())

    expect_flash(type: :error, message: "Roles need to be assigned.")

    # Remove the user from the project
    principal_page.remove_from_project!(project.name)
    principal_page.expect_no_membership(project.name)

    # Re-add the user
    principal_page.add_to_project! project.name, as: %w(Manager Developer)

    principal_page.expect_project(project.name)
    principal_page.expect_roles(project.name, %w(Manager Developer))
  end
end

RSpec.shared_examples "global user principal membership management flows" do |permission|
  context "as global user" do
    shared_let(:global_user) { create(:user, global_permissions: [permission]) }
    shared_let(:project_members) { { global_user => manager } }
    current_user { global_user }

    context "when the user is member in the projects" do
      it_behaves_like "principal membership management flows" do
        before do
          Members::CreateService
            .new(user: User.system, contract_class: EmptyContract)
            .call(principal: global_user,
                  project:,
                  roles: [manager])

          Members::CreateService
            .new(user: User.system, contract_class: EmptyContract)
            .call(principal: global_user,
                  project: project2,
                  roles: [manager])
        end
      end
    end

    context "when the user cannot see the two projects" do
      it "does not show them" do
        principal_page.visit!
        principal_page.open_projects_tab!

        expect(page).to have_no_css("#membership_project_id option", text: project.name, visible: :all)
        expect(page).to have_no_css("#membership_project_id option", text: project2.name, visible: :all)
      end

      it "does not show the membership" do
        Members::CreateService
          .new(user: User.system, contract_class: EmptyContract)
          .call(principal:,
                project:,
                roles: [developer])

        principal_page.visit!
        principal_page.open_projects_tab!

        expect(page).to have_no_css("tr.member")
        expect(page).to have_text "There is currently nothing to display."
        expect(page).to have_no_text project2.name
        expect(page).to have_no_text project2.name
      end
    end
  end

  context "as user with global and project permissions, but not manage_members" do
    current_user do
      create(:user,
             global_permissions: permission,
             member_with_permissions: { project => %i[view_work_packages] })
    end

    it "does not allow to select that project" do
      principal_page.visit!
      principal_page.open_projects_tab!

      expect(page).to have_no_css("tr.member")
      expect(page).to have_text "There is currently nothing to display."
      expect(page).to have_no_text project.name
      expect(page).to have_no_text project2.name
    end
  end

  context "as user without global permission" do
    current_user { create(:user) }

    it "returns an error" do
      principal_page.visit!
      expect(page).to have_text "You are not authorized to access this page."
      expect(page).to have_no_text principal.name
    end
  end
end
