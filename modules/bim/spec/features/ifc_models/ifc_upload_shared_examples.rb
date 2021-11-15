shared_examples 'can upload an IFC file' do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create :project, enabled_module_names: %i[bim] }
  let(:ifc_fixture) { ::UploadedFile.load_from('modules/bim/spec/fixtures/files/minimal.ifc') }

  before do
    login_as user

    allow_any_instance_of(Bim::IfcModels::BaseContract).to receive(:ifc_attachment_is_ifc).and_return true
  end

  it 'should allow uploading an IFC file' do
    visit new_bcf_project_ifc_model_path(project_id: project.identifier)

    page.attach_file("file", ifc_fixture.path, visible: :all)

    click_on "Create"

    expect(page).to have_content("Upload succeeded")

    expect(Attachment.count).to eq 1
    expect(Attachment.first[:file]).to eq model_name

    expect(Bim::IfcModels::IfcModel.count).to eq 1
  end
end
