require 'spec_helper'
require 'spreadsheet'
require 'models/projects/exporter/exportable_project_context'

RSpec.describe XlsExport::Project::Exporter::XLS do
  include_context 'with a project with an arrangement of custom fields'
  include_context 'with an instance of the described exporter'

  let(:sheet) do
    io = StringIO.new output
    Spreadsheet.open(io).worksheets.first
  end

  let(:header) { sheet.rows.first.compact } # raw values have trailing nil
  let(:rows) { sheet.rows.drop(1) }

  describe 'empty result' do
    before do
      allow(instance).to receive(:records).and_return([])
    end

    it 'returns an empty XLS' do
      expect(sheet.rows.count).to eq 1
      expect(rows).to be_empty
    end
  end

  it 'performs a successful export' do
    expect(rows.count).to eq(1)
    expect(sheet.row(1)).to eq [project.id.to_s, project.identifier,
                                project.name, project.description, 'Off track', 'false']
  end

  context 'with project description containing html' do
    before do
      project.update(description: "This is an <p>html</p> description.")
    end

    it 'performs a successful export' do
      expect(rows.count).to eq(1)
      expect(sheet.row(1)).to eq [project.id.to_s, project.identifier, project.name,
                                  "This is an html description.", 'Off track', 'false']
    end
  end

  context 'with status_explanation enabled' do
    let(:query_columns) { %w[name description project_status status_explanation public ] }

    it 'performs a successful export' do
      expect(rows.count).to eq(1)
      expect(sheet.row(1)).to eq [project.id.to_s, project.identifier,
                                  project.name, project.description,
                                  'Off track', project.status_explanation, 'false']
    end
  end

  describe 'custom field columns selected' do
    let(:query_columns) { %w[name description project_status public] + custom_fields.map(&:column_name) }
    let(:current_user) { build_stubbed(:admin) }

    context 'when ee enabled', with_ee: %i[custom_fields_in_projects_list] do
      it 'renders all those columns' do
        cf_names = custom_fields.map(&:name)
        expect(header).to eq ['ID', 'Identifier', 'Name', 'Description', 'Status', 'Public', *cf_names]

        custom_values = custom_fields.map do |cf|
          case cf
          when bool_cf
            'true'
          when text_cf
            project.typed_custom_value_for(cf)
          else
            project.formatted_custom_value_for(cf)
          end
        end

        expect(sheet.row(1))
          .to eq [project.id.to_s, project.identifier, project.name, project.description, 'Off track', 'false', *custom_values]
      end
    end

    context 'when ee not enabled' do
      it 'renders only the default columns' do
        expect(header).to eq %w[ID Identifier Name Description Status Public]
      end
    end
  end

  context 'with no project visible' do
    let(:current_user) { User.anonymous }

    it 'does not include the project' do
      expect(output).not_to include project.identifier
      expect(rows).to be_empty
    end
  end
end
