require 'spec_helper'

RSpec.describe 'Work package single context menu', js: true do
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package) }

  let(:wp_view) { Pages::FullWorkPackage.new(work_package, work_package.project) }

  before do
    login_as(user)
    wp_view.visit!
  end

  it 'sets the correct copy project link' do
    find('#action-show-more-dropdown-menu .button').click
    find('.menu-item', text: 'Copy to other project', exact_text: true).click

    expect(page).to have_selector('h2', text: I18n.t(:button_copy))
    expect(page).to have_selector('a.work_package', text: "##{work_package.id}")
    expect(page).to have_current_path /work_packages\/move\/new\?copy=true&ids\[\]=#{work_package.id}/
  end
end
