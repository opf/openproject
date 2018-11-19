require 'spec_helper'

describe WorkPackagesController, 'rendering to xls', type: :controller do
  let(:current_user) { FactoryBot.create(:admin) }
  let!(:work_package) do
    FactoryBot.create(:work_package,
                       subject: '!SUBJECT!',
                       description: '!DESCRIPTION!')
  end

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe "should respond with the xls if requested in the index" do
    before do
      get('index', params: { format: 'xls', project_id: work_package.project_id })
    end

    it 'should respond with 200 OK' do
      expect(response.response_code).to eq(200)
    end

    it 'should have a length > 100 bytes' do
      expect(response.body.length).to be > 100
    end

    it 'should not contain a description' do
      expect(response.body).not_to include('!DESCRIPTION!')
    end

    it 'should contain a subject' do
      expect(response.body).to include('!SUBJECT!')
    end

    context 'the mime type' do
      it { expect(response.header['Content-Type']).to eq('application/vnd.ms-excel') }
    end
  end

  describe 'with cost and time entries' do
    # Since this test has to work without the actual costs plugin we'll just add
    # a custom field called 'costs' to emulate it.

    let(:custom_field) do
      FactoryBot.create(:float_wp_custom_field,
                         name: 'unit costs')
    end
    let(:custom_value) do
      FactoryBot.create(:custom_value,
                         custom_field: custom_field)
    end
    let(:type) do
      type = project.types.first
      type.custom_fields << custom_field
      type
    end
    let(:project) do
      FactoryBot.create(:project,
                         work_package_custom_fields: [custom_field])
    end
    let(:work_packages) do
      wps = FactoryBot.create_list(:work_package, 4,
                                    project: project,
                                    type: type)
      wps[0].estimated_hours = 27.5
      wps[0].save!
      wps[1].send(:"custom_field_#{custom_field.id}=", 1)
      wps[1].save!
      wps[2].send(:"custom_field_#{custom_field.id}=", 99.99)
      wps[2].save!
      wps[3].send(:"custom_field_#{custom_field.id}=", 1000)
      wps[3].save!
      wps
    end

    before do
      allow(OpenProject::XlsExport::Formatters::TimeFormatter).to receive(:apply?) do |column|
        column.caption =~ /time/i
      end

      allow(OpenProject::XlsExport::Formatters::CostFormatter).to receive(:apply?) do |column|
        column.caption =~ /cost/i
      end

      allow(Setting).to receive(:plugin_openproject_costs).and_return('costs_currency' => 'EUR', 'costs_currency_format' => '%n %u')

      get 'index',
          params: {
            format: 'xls',
            project_id: work_packages.first.project_id,
            set_filter: '1',
            c: ['subject',
                'status',
                'estimated_hours',
                "cf_#{custom_field.id}"],
            sortBy: JSON::dump(['id:asc'])
          }

      expect(response.response_code).to eq(200)

      f = Tempfile.new 'result.xls'
      begin
        f.binmode
        f.write response.body
      ensure
        f.close
      end

      require 'spreadsheet'

      @sheet = Spreadsheet.open(f.path).worksheets.first
      f.unlink
    end

    it 'should successfully export the work packages with a cost column' do
      expect(@sheet.rows.size).to eq(4 + 1)

      cost_column = @sheet.columns.last.to_a
      [1.0, 99.99, 1000.0].each do |value|
        expect(cost_column).to include(value)
      end
    end

    it 'should include estimated hours' do
      expect(@sheet.rows.size).to eq(4 + 1)

      # Check row after header row
      hours = @sheet.rows[1].values_at(2)
      expect(hours).to include(27.5)
    end
  end

  context 'with descriptions' do
    before do
      get 'index',
          params: {
            format: 'xls',
            project_id: work_package.project_id,
            show_descriptions: 'true'
          }
    end

    it 'should respond with 200 OK' do
      expect(response.response_code).to eq(200)
    end

    it 'should have a length > 100 bytes' do
      expect(response.body.length).to be > 100
    end

    it 'should contain a description' do
      expect(response.body).to include('!DESCRIPTION!')
    end

    it 'should contain a subject' do
      expect(response.body).to include('!SUBJECT!')
    end

    it 'returns the xls mime mime type' do
      expect(response.header['Content-Type'])
        .to eq('application/vnd.ms-excel')
    end
  end

  describe 'empty result' do
    before do
      work_package.delete

      get 'index', params: { format: 'xls', project_id: work_package.project_id }
    end

    it 'should yield an empty XLS file' do
      expect(response.response_code).to be(200)

      f = Tempfile.new 'result.xls'
      begin
        f.binmode
        f.write response.body
      ensure
        f.close
      end

      require 'spreadsheet'

      sheet = Spreadsheet.open(f.path).worksheets.first
      expect(sheet.rows.size).to eq(1) # just the headers
    end
  end

  describe 'with user time zone' do
    let(:zone) { +2 }

    before do
      allow(current_user).to receive(:time_zone).and_return(zone)

      allow(OpenProject::XlsExport::Formatters::TimeFormatter).to receive(:apply?) do |column|
        column.caption =~ /time/i
      end

      get 'index',
          params: {
            format: 'xls',
            project_id: work_package.project_id,
            set_filter: '1',
            c: ['subject', 'status', 'updated_at']
          }

      expect(response.response_code).to eq(200)

      f = Tempfile.new 'result.xls'
      begin
        f.binmode
        f.write response.body
      ensure
        f.close
      end

      require 'spreadsheet'

      @sheet = Spreadsheet.open(f.path).worksheets.first
      f.unlink
    end

    it 'should adapt the datetime fields to the user time zone' do
      work_package.reload
      updated_at_cell = @sheet.rows.last.to_a.last
      expect(updated_at_cell.to_s(:number)).to eq(work_package.updated_at.in_time_zone(zone).to_s(:number))
    end
  end
end
