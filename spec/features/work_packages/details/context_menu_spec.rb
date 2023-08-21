require 'spec_helper'

RSpec.describe 'Work package single context menu', js: true do
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package) }

  let(:wp_view) { Pages::FullWorkPackage.new(work_package, work_package.project) }

  before do
    login_as(user)
    wp_view.visit!
    find('#action-show-more-dropdown-menu .button').click
  end

  it 'sets the correct copy project link' do
    find('.menu-item', text: 'Copy to other project', exact_text: true).click
    expect(page).to have_selector('h2', text: I18n.t(:button_copy))
    expect(page).to have_selector('a.work_package', text: "##{work_package.id}")
    expect(page).to have_current_path /work_packages\/move\/new\?copy=true&ids\[\]=#{work_package.id}/
  end

  it 'successfully copies the short url of the work package' do
    find('.menu-item', text: 'Copy link to clipboard', exact_text: true).click

    # We cannot access the navigator.clipboard from a headless browser.
    # This test makes sure the copy to clipboard logic is working,
    # regardless of the browser permissions.
    expect(page).to have_content("/wp/#{work_package.id}")
  end
end
