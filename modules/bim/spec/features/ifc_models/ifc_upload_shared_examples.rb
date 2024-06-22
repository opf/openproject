RSpec.shared_examples "can upload an IFC file" do
  let(:user) { create(:admin) }
  let(:project) { create(:project, enabled_module_names: %i[bim]) }
  let(:ifc_fixture) { UploadedFile.load_from("modules/bim/spec/fixtures/files/minimal.ifc") }
  let(:set_tick_is_default_after_file) { true }

  before do
    login_as user

    allow_any_instance_of(Bim::IfcModels::BaseContract).to receive(:ifc_attachment_is_ifc).and_return true
  end

  shared_examples "allows uploading an IFC file" do
    it "allows uploading an IFC file" do
      visit new_bcf_project_ifc_model_path(project_id: project.identifier)

      page.find_by_id("bim_ifc_models_ifc_model_is_default").set(true) unless set_tick_is_default_after_file
      page.attach_file("file", ifc_fixture.path, visible: :all)
      page.find_by_id("bim_ifc_models_ifc_model_is_default").set true if set_tick_is_default_after_file

      click_on "Create"

      expect(page).to have_content("Upload succeeded")

      expect(Attachment.count).to eq 1
      expect(Attachment.first[:file]).to eq model_name

      expect(Bim::IfcModels::IfcModel.count).to eq 1

      expect(Bim::IfcModels::IfcModel.first.is_default).to be_truthy
    end
  end

  context "when setting checkbox is_default before selecting file" do
    let(:set_tick_is_default_after_file) { false }

    it_behaves_like "allows uploading an IFC file"
  end

  context "when setting checkbox is_default after selecting file" do
    it_behaves_like "allows uploading an IFC file"
  end
end
