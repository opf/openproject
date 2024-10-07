require "spec_helper"
require "features/page_objects/notification"

RSpec.describe "Bulk update work packages through Rails view", :js, :with_cuprite do
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:project) { create(:project, name: "Source", types: [type]) }
  shared_let(:status) { create(:status) }
  shared_let(:custom_field) do
    create(:string_wp_custom_field,
           name: "Text CF",
           types: [type],
           projects: [project])
  end
  shared_let(:custom_field_removed) do
    create(:string_wp_custom_field,
           name: "Text CF Removed",
           types: [type],
           projects: [project])
  end
  shared_let(:dev_role) do
    create(:project_role,
           permissions: %i[view_work_packages])
  end
  shared_let(:mover_role) do
    create(:project_role,
           permissions: %i[view_work_packages copy_work_packages move_work_packages manage_subtasks add_work_packages])
  end
  shared_let(:dev) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_roles: { project => dev_role })
  end
  shared_let(:mover) do
    create(:admin,
           firstname: "Manager",
           lastname: "Guy",
           member_with_roles: { project => mover_role })
  end

  shared_let(:work_package) do
    create(:work_package,
           author: dev,
           status:,
           project:,
           type:)
  end

  shared_let(:status2) { create(:default_status) }
  shared_let(:workflow) do
    create(:workflow,
           type_id: type.id,
           old_status: work_package.status,
           new_status: status2,
           role: mover_role)
  end

  let(:work_package2_status) { status }
  let!(:work_package2) do
    create(:work_package,
           author: dev,
           status: work_package2_status,
           project:,
           type:)
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:notes) { Components::WysiwygEditor.new }

  before do
    login_as current_user
    wp_table.visit!
    expect_angular_frontend_initialized
    wp_table.expect_work_package_listed work_package, work_package2

    # Select all work packages
    find("body").send_keys [:control, "a"]
  end

  context "with permission" do
    let(:current_user) { mover }

    before do
      context_menu.open_for work_package
      context_menu.choose "Bulk edit"

      notes.set_markdown("The typed note")
    end

    it "sets status and leaves a note" do
      select status2.name, from: "work_package_status_id"
      click_on "Submit"

      expect_angular_frontend_initialized
      wp_table.expect_work_package_count 2

      # Should update the status
      expect([work_package.reload.status_id, work_package2.reload.status_id].uniq)
        .to eq([status2.id])

      expect([work_package.journals.last.notes, work_package2.journals.last.notes].uniq)
        .to eq(["The typed note"])
    end

    context "when making an error in the form" do
      let(:work_package2_status) { create(:status) } # without creating a workflow

      it "does not update the work packages" do
        select status2.name, from: "work_package_status_id"
        fill_in "Parent", with: "-1"
        click_on "Submit"

        expect_flash(type: :error, message: I18n.t("work_packages.bulk.none_could_be_saved", total: 2))
        expect_flash(type: :error,
                     message: "#{work_package.id}: Parent #{I18n.t('activerecord.errors.messages.does_not_exist')}")

        expect_flash(type: :error, message:
          <<~MSG.squish
            #{work_package2.id}:
            Parent #{I18n.t('activerecord.errors.messages.does_not_exist')}
            Status #{I18n.t('activerecord.errors.models.work_package.attributes.status_id.status_transition_invalid')}
          MSG
        )

        # Should not update the status
        work_package2.reload
        work_package.reload
        expect(work_package.status_id).to eq(status.id)
        expect(work_package2.status_id).to eq(work_package2_status.id)
      end
    end

    describe "custom fields" do
      context "when editing custom field of work packages with a readonly status (regression#44673)" do
        let(:work_package2_status) { create(:status, :readonly) }

        context "with enterprise", with_ee: %i[readonly_work_packages] do
          it "does not update the work packages" do
            expect(work_package.send(custom_field.attribute_getter)).to be_nil
            expect(work_package2.send(custom_field.attribute_getter)).to be_nil

            fill_in custom_field.name, with: "Custom field text"
            click_on "Submit"

            expect_flash(type: :error, message:
              I18n.t("work_packages.bulk.x_out_of_y_could_be_saved", total: 2, failing: 1, success: 1))

            expect_flash(type: :error, message:
              <<~MSG.squish
                #{work_package2.id}:
                #{custom_field.name} #{I18n.t('activerecord.errors.messages.error_readonly')}
                #{I18n.t('activerecord.errors.models.work_package.readonly_status')}
              MSG
            )

            # Should update 1 work package custom field only
            work_package.reload
            work_package2.reload

            expect(work_package.send(custom_field.attribute_getter))
              .to eq("Custom field text")

            expect(work_package2.send(custom_field.attribute_getter))
              .to be_nil
          end
        end

        context "without enterprise", with_ee: false do
          it "ignores the readonly status and updates the work packages" do
            expect(work_package.send(custom_field.attribute_getter)).to be_nil
            expect(work_package2.send(custom_field.attribute_getter)).to be_nil

            fill_in custom_field.name, with: "Custom field text"
            click_on "Submit"

            expect_and_dismiss_flash(message: I18n.t(:notice_successful_update))

            # Should update 2 work package custom fields
            work_package.reload
            work_package2.reload

            expect(work_package.send(custom_field.attribute_getter))
              .to eq("Custom field text")

            expect(work_package2.send(custom_field.attribute_getter))
              .to eq("Custom field text")
          end
        end
      end

      describe "unsetting values for different fields" do
        let(:boolean_cf) do
          create(:boolean_wp_custom_field,
                 name: "Bool CF",
                 types: [type],
                 projects: [project])
        end
        let(:required_boolean_cf) do
          create(:boolean_wp_custom_field,
                 name: "Required Bool CF",
                 types: [type],
                 projects: [project],
                 is_required: true)
        end
        let(:list_cf) do
          create(:list_wp_custom_field,
                 name: "List CF",
                 types: [type],
                 projects: [project],
                 possible_values: %w[A B C])
        end
        let(:required_list_cf) do
          create(:list_wp_custom_field,
                 name: "Required List CF",
                 types: [type],
                 projects: [project],
                 possible_values: %w[A B C],
                 is_required: true)
        end
        let(:multi_list_cf) do
          create(:list_wp_custom_field, :multi_list,
                 name: "Multi select List CF",
                 types: [type],
                 projects: [project],
                 possible_values: %w[A B C])
        end
        let(:user_cf) do
          create(:user_wp_custom_field,
                 name: "User CF",
                 types: [type],
                 projects: [project])
        end
        let(:multi_user_cf) do
          create(:user_wp_custom_field, :multi_user,
                 name: "Multi user CF",
                 types: [type],
                 projects: [project])
        end

        let(:default_cf_values) do
          {
            boolean_cf.id => true,
            required_boolean_cf.id => false,
            list_cf.id => list_cf.custom_options.find_by(value: "B"),
            required_list_cf.id => required_list_cf.custom_options.find_by(value: "B"),
            multi_list_cf.id => multi_list_cf.custom_options.find_by(value: "B"),
            user_cf.id => dev,
            multi_user_cf.id => [dev, mover]
          }
        end

        before do
          [work_package, work_package2].each do |wp|
            wp.update!(custom_field_values: default_cf_values)
          end

          refresh
          wait_for_reload
        end

        it "clears the chosen values" do
          # Required fields should not have a 'none' option
          expect(page).to have_no_select(required_boolean_cf.name, with_options: ["none"])
          expect(page).to have_no_select(required_list_cf.name, with_options: ["none"])

          # Unset any non-required fields
          select "none", from: boolean_cf.name
          select "none", from: list_cf.name
          select "none", from: multi_list_cf.name
          select "nobody", from: user_cf.name
          select "nobody", from: multi_user_cf.name

          click_on "Submit"

          expect_angular_frontend_initialized
          wp_table.expect_work_package_count 2

          # It clears all the values except the required fields
          expect(work_package.reload.custom_field_values.pluck(:value).compact)
            .to eq(["f", required_list_cf.custom_options.find_by(value: "B").id.to_s])
          expect(work_package2.reload.custom_field_values.pluck(:value).compact)
            .to eq(["f", required_list_cf.custom_options.find_by(value: "B").id.to_s])
        end
      end

      context "when custom fields are removed from types" do
        it "does not display them on the form" do
          expect(page).to have_field custom_field_removed.name

          custom_field_removed.types = []
          custom_field_removed.save!
          page.refresh
          wait_for_reload

          expect(page).to have_no_field custom_field_removed.name
        end
      end
    end
  end

  context "without permission" do
    let(:current_user) { dev }

    it "does not allow to copy" do
      context_menu.open_for work_package
      context_menu.expect_no_options "Bulk edit"
    end
  end
end
