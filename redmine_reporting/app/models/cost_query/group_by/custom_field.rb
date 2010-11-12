module CostQuery::GroupBy
  class CustomField < Base
    extend CostQuery::CustomFieldMixin
    on_prepare { group_fields table_name }
  end
end
