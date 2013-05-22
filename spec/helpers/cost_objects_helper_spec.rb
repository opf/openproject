require File.dirname(__FILE__) + '/../spec_helper'

describe CostObjectsHelper do
  let(:project) { FactoryGirl.build(:project) }
  let(:cost_object) { FactoryGirl.build(:cost_object, :project => project) }

  describe :cost_objects_to_csv do
    describe "WITH a list of one cost object" do

      it "should output the cost objects attributes" do
        expected = [cost_object.id,
                    l(cost_object.status),
                    cost_object.project.name,
                    cost_object.subject,
                    cost_object.author.name,
                    helper.format_date(cost_object.fixed_date),
                    helper.number_to_currency(cost_object.material_budget),
                    helper.number_to_currency(cost_object.labor_budget),
                    helper.number_to_currency(cost_object.spent),
                    helper.format_time(cost_object.created_on),
                    helper.format_time(cost_object.updated_on),
                    cost_object.description
                  ].join(I18n.t(:general_csv_separator))

        cost_objects_to_csv([cost_object]).include?(expected).should be_true
      end

      it "should start with a header explaining the fields" do
        expected = [ "#",
                    l(:field_status),
                    l(:field_project),
                    l(:field_subject),
                    l(:field_author),
                    l(:field_fixed_date),
                    l(:field_material_budget),
                    l(:field_labor_budget),
                    l(:field_spent),
                    l(:field_created_on),
                    l(:field_updated_on),
                    l(:field_description)
                    ].join(I18n.t(:general_csv_separator))

        cost_objects_to_csv([cost_object]).start_with?(expected).should be_true
      end
    end
  end
end
