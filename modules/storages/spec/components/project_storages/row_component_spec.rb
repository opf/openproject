require 'rails_helper'

RSpec.describe Storages::ProjectStorages::RowComponent,
               type: :component do
  describe '#button_links' do
    context 'with non-automatic project storage' do
      it 'renders edit and delete buttons' do
        project_storage = build_stubbed(:project_storage)
        expect(project_storage).not_to be_project_folder_automatic

        table = instance_double(Storages::ProjectStorages::TableComponent, columns: [])
        component = described_class.new(row: project_storage, table:)

        render_inline(component)

        expect(page).not_to have_css('a.icon.icon-group')
        expect(page).to have_css('a.icon.icon-edit')
        expect(page).to have_css('a.icon.icon-delete')
      end
    end

    context 'with automatic project storage' do
      it 'renders members connection status, edit and delete buttons' do
        project_storage = build_stubbed(:project_storage, :as_automatically_managed)
        expect(project_storage).to be_project_folder_automatic

        table = instance_double(Storages::ProjectStorages::TableComponent, columns: [])
        component = described_class.new(row: project_storage, table:)

        render_inline(component)

        expect(page).to have_css('a.icon.icon-group')
        expect(page).to have_css('a.icon.icon-edit')
        expect(page).to have_css('a.icon.icon-delete')
      end
    end
  end
end
