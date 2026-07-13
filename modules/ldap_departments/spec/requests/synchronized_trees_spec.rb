# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "LDAP department synchronized trees", :aggregate_failures, :skip_csrf,
               type: :rails_request, with_ee: %i[ldap_groups] do
  shared_let(:admin) { create(:admin) }
  shared_let(:ldap_auth_source) { create(:ldap_auth_source, base_dn: "dc=example,dc=com") }

  before { login_as(admin) }

  describe "GET /ldap_departments/synchronized_trees" do
    it "renders the empty index" do
      get ldap_departments_synchronized_trees_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the index with existing trees" do
      create(:ldap_synchronized_tree, ldap_auth_source:)

      get ldap_departments_synchronized_trees_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /ldap_departments/synchronized_trees/:id" do
    let(:tree) { create(:ldap_synchronized_tree, ldap_auth_source:) }

    it "renders the tree with its synchronized departments" do
      create(:ldap_synchronized_department, synchronized_tree: tree)

      get ldap_departments_synchronized_tree_path(tree_id: tree.id)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /ldap_departments/synchronized_trees" do
    let(:params) do
      {
        synchronized_tree: {
          name: "IT directory",
          ldap_auth_source_id: ldap_auth_source.id,
          base_dn: "ou=IT,dc=example,dc=com",
          structure_filter_string: "(objectClass=organizationalUnit)",
          ou_name_attribute: "ou",
          sync_users: "1"
        }
      }
    end

    it "creates a synchronized tree and starts the background synchronization" do
      allow(LdapDepartments::SynchronizeTreeJob).to receive(:perform_later)

      expect { post ldap_departments_synchronized_trees_path, params: }
        .to change(LdapDepartments::SynchronizedTree, :count).by(1)

      tree = LdapDepartments::SynchronizedTree.last
      expect(response).to redirect_to(ldap_departments_synchronized_tree_path(tree_id: tree.id))
      expect(tree.base_dn).to eq("ou=IT,dc=example,dc=com")
      expect(LdapDepartments::SynchronizeTreeJob).to have_received(:perform_later).with(tree)
    end

    it "rejects an out-of-base DN" do
      params[:synchronized_tree][:base_dn] = "ou=IT,dc=other,dc=com"

      expect { post ldap_departments_synchronized_trees_path, params: }
        .not_to change(LdapDepartments::SynchronizedTree, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /ldap_departments/synchronized_trees/:id/deletion_dialog" do
    let!(:tree) { create(:ldap_synchronized_tree, ldap_auth_source:, name: "IT directory") }

    it "renders the danger confirmation dialog explaining departments are kept" do
      get deletion_dialog_ldap_departments_synchronized_tree_path(tree_id: tree.id), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("ldap_departments.synchronized_trees.destroy.info"))
    end
  end

  describe "DELETE /ldap_departments/synchronized_trees/:id" do
    let!(:tree) { create(:ldap_synchronized_tree, ldap_auth_source:) }

    it "removes the tree" do
      expect { delete ldap_departments_synchronized_tree_path(tree_id: tree.id) }
        .to change(LdapDepartments::SynchronizedTree, :count).by(-1)
    end
  end

  describe "POST /ldap_departments/synchronized_trees/:id/synchronize" do
    let!(:tree) { create(:ldap_synchronized_tree, ldap_auth_source:) }

    it "enqueues a background synchronization and redirects" do
      allow(LdapDepartments::SynchronizeTreeJob).to receive(:perform_later)

      post synchronize_ldap_departments_synchronized_tree_path(tree_id: tree.id)

      expect(LdapDepartments::SynchronizeTreeJob).to have_received(:perform_later).with(tree)
      expect(response).to redirect_to(ldap_departments_synchronized_tree_path(tree_id: tree.id))
    end
  end

  context "without the enterprise feature" do
    before do
      allow(EnterpriseToken).to receive(:allows_to?).and_call_original
      allow(EnterpriseToken).to receive(:allows_to?).with(:ldap_groups).and_return(false)
    end

    it "redirects away from the new form" do
      get new_ldap_departments_synchronized_tree_path

      expect(response).to have_http_status(:see_other)
    end

    # An instance that lost its enterprise token must still be able to clean up trees it set up.
    it "still allows deleting a tree" do
      tree = create(:ldap_synchronized_tree, ldap_auth_source:)

      expect { delete ldap_departments_synchronized_tree_path(tree_id: tree.id) }
        .to change(LdapDepartments::SynchronizedTree, :count).by(-1)
    end

    it "still renders the deletion dialog" do
      tree = create(:ldap_synchronized_tree, ldap_auth_source:)

      get deletion_dialog_ldap_departments_synchronized_tree_path(tree_id: tree.id), as: :turbo_stream

      expect(response).to have_http_status(:ok)
    end
  end
end
