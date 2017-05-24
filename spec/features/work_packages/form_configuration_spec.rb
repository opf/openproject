require 'spec_helper'

describe 'form configuration: ', js: true do
  describe 'showing the work package' do
    let(:user) { FactoryGirl.create :admin }
    let(:type) { work_package.type }

    let(:version) do
      FactoryGirl.create :version, name: '42.0', project: work_package.project
    end

    let(:work_package) { FactoryGirl.create :work_package, author: user }
    let(:wp_page)      { Pages::FullWorkPackage.new work_package }

    before do
      login_as user
    end

    describe 'with version having no visibility configured' do
      it 'shows the version field if one is set (default behaviour)' do
        work_package.update! fixed_version: version

        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_attributes Version: '42.0'
      end

      it 'hides the version field if none is set (default behaviour)' do
        work_package.update! fixed_version: nil

        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_attribute_hidden 'Version'
      end
    end

    describe 'with version having its visibility set to default' do
      before do
        type.attribute_visibility['version'] = 'default'
        type.save!
      end

      it 'shows the version field if one is set' do
        work_package.update! fixed_version: version

        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_attributes Version: '42.0'
      end

      it 'hides the version field if none is set' do
        work_package.update! fixed_version: nil

        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_attribute_hidden 'Version'
      end
    end

    describe 'with version having its visibility set to hidden' do
      before do
        type.attribute_visibility['version'] = 'hidden'
        type.save!
      end

      it 'hides the version field even if one is set' do
        work_package.update! fixed_version: version

        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_attribute_hidden 'Version'
      end

      it 'hides the version field if none is set' do
        work_package.update! fixed_version: nil

        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_attribute_hidden 'Version'
      end
    end

    describe 'with version having its visibility set to visible' do
      before do
        type.attribute_visibility['version'] = 'visible'
        type.save!
      end

      it 'shows the version field if one is set' do
        work_package.update! fixed_version: version

        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_attributes Version: '42.0'
      end

      it 'shows the version field even if none is set' do
        work_package.update! fixed_version: nil

        wp_page.visit!
        wp_page.ensure_page_loaded

        wp_page.expect_attributes Version: nil
      end
    end

    context 'during creation' do
      context 'with version having default visibility' do
        before do
          type.attribute_visibility['version'] = 'default'
          type.save!

          wp_page.visit!

          wp_page.expect_attribute_hidden :version

          wp_page.click_create_wp_button type
        end

        it 'version is not shown' do
          expect(page).not_to have_text 'Version'
          find('#work-packages--edit-actions-cancel').click
          expect(wp_page).not_to have_alert_dialog
          loading_indicator_saveguard
        end
      end

      context 'with version always shown' do
        before do
          type.attribute_visibility['version'] = 'visible'
          type.save!

          wp_page.visit!

          wp_page.expect_attributes Version: nil

          wp_page.click_create_wp_button type
        end

        it 'version is shown' do
          expect(page).to have_text 'Version'
          find('#work-packages--edit-actions-cancel').click
          expect(wp_page).not_to have_alert_dialog
          loading_indicator_saveguard
        end
      end
    end
  end
end
