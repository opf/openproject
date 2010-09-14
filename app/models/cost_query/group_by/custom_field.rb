module CostQuery::GroupBy
  class CustomField < Base
    def self.all
      @all ||= generate_subclasses
    end

    def self.generate_subclasses
      IssueCustomField.all.map do |field|
        class_name = class_name_for field.name
        CostQuery::GroupBy.send(:remove_const, class_name) if CostQuery::GroupBy.const_defined? class_name
        CostQuery::GroupBy.const_set class_name, Class.new(self).prepare(field, class_name)
      end
    end

    def self.prepare(field, class_name)
      label field.name
      table_name(class_name.demodulize.underscore.tableize)
      dont_inherit :group_fields
      group_fields table_name
      join_table(<<-SQL % [CustomValue.table_name, table_name, field.id, field.name])
      -- BEGIN Custom Field Join: "%4$s"
      LEFT OUTER JOIN (
        SELECT
          value AS %2$s,
          customized_type,
          custom_field_id,
          customized_id
        FROM
          %1$s)
      AS %2$s
      ON %2$s.customized_type = 'Issue'
      AND %2$s.custom_field_id = %3$d
      AND %2$s.customized_id = entries.issue_id
      -- END Custom Field Join: "%4$s"
      SQL
      self
    end

    def self.new(*)
      fail "Only subclasses of #{self} should be instanciated." unless self < CustomField
      super
    end

    def self.class_name_for(field)
      "CustomField" << field.split(/[ \-_]/).map { |part| part.gsub(/\W/, '').capitalize }.join
    end
  end
end
