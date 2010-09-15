module CostQuery::CustomFieldMixin
  def self.extended(base)
    base.inherited_attribute :factory
    base.factory = base
    super
  end

  def all
    @all ||= generate_subclasses
  end

  def generate_subclasses
    IssueCustomField.all.map do |field|
      class_name = class_name_for field.name
      parent.send(:remove_const, class_name) if CostQuery::GroupBy.const_defined? class_name
      parent.const_set class_name, Class.new(self).prepare(field, class_name)
    end
  end

  def on_prepare(&block)
    @on_prepare = block if block
    @on_prepare
  end

  def prepare(field, class_name)
    label field.name
    table_name(class_name.demodulize.underscore.tableize)
    dont_inherit :group_fields
    join_table (<<-SQL % [CustomValue.table_name, table_name, field.id, field.name]).gsub(/^    /, "\t")
    -- BEGIN Custom Field Join: "%4$s"
    LEFT OUTER JOIN (
    \tSELECT
    \t\tvalue AS %2$s,
    \t\tcustomized_type,
    \t\tcustom_field_id,
    \t\tcustomized_id
    \tFROM
    \t\t%1$s)
    AS %2$s
    ON %2$s.customized_type = 'Issue'
    AND %2$s.custom_field_id = %3$d
    AND %2$s.customized_id = entries.issue_id
    -- END Custom Field Join: "%4$s"
    SQL
    instance_eval(&factory.on_prepare)
    self
  end

  def new(*)
    fail "Only subclasses of #{self} should be instanciated." unless self < factory
    super
  end

  def class_name_for(field)
    "CustomField" << field.split(/[ \-_]/).map { |part| part.gsub(/\W/, '').capitalize }.join
  end
end