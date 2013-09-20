class CostQuery::GroupBy::CustomFieldEntries < Report::GroupBy::Base
  applies_for :label_work_package_attributes
  extend CostQuery::CustomFieldMixin
  on_prepare { group_fields table_name }
end
