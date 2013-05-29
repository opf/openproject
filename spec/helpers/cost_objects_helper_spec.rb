require File.dirname(__FILE__) + '/../spec_helper'

describe CostObjectsHelper do
  let(:project) { FactoryGirl.build(:project) }
  let(:cost_object) { FactoryGirl.build(:cost_object, :project => project) }

  describe :cost_objects_to_csv do
    describe "WITH a list of one cost object" do

      it "should output the cost objects attributes" do
        expected = [cost_object.id,
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
        expected = ["#",
                    Project.model_name.human,
                    CostObject.human_attribute_name(:subject),
                    CostObject.human_attribute_name(:author),
                    CostObject.human_attribute_name(:fixed_date),
                    VariableCostObject.human_attribute_name(:material_budget),
                    VariableCostObject.human_attribute_name(:labor_budget),
                    CostObject.human_attribute_name(:spent),
                    CostObject.human_attribute_name(:created_on),
                    CostObject.human_attribute_name(:updated_on),
                    CostObject.human_attribute_name(:description)
                    ].join(I18n.t(:general_csv_separator))

        cost_objects_to_csv([cost_object]).start_with?(expected).should be_true
      end
    end
  end
end
