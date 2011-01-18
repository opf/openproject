module CostQuery::CustomFieldMixin
  include Report::QueryUtils

  attr_reader :custom_field
  SQL_TYPES = {
    'string' => mysql? ? 'char' : 'varchar',
    'list'   => mysql? ? 'char' : 'varchar',
    'text'   => mysql? ? 'char' : 'text',
    'bool'   => mysql? ? 'unsigned' : 'boolean',
    'date'  => 'date',
    'int'   => 'decimal(60,3)', 'float' => 'decimal(60,3)' }

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
      parent.send(:remove_const, class_name) if parent.const_defined? class_name
      parent.const_set class_name, Class.new(self).prepare(field, class_name)
    end
  end

  def factory?
    factory == self
  end

  def on_prepare(&block)
    return factory.on_prepare unless factory?
    @on_prepare = block if block
    @on_prepare ||= proc { }
    @on_prepare
  end

  def table_name
    @class_name.demodulize.underscore.tableize.singularize
  end

  def prepare(field, class_name)
    @custom_field = field
    label field.name
    @class_name = class_name
    dont_inherit :group_fields
    db_field table_name
    join_table (<<-SQL % [CustomValue.table_name, table_name, field.id, field.name, SQL_TYPES[field.field_format]]).gsub(/^    /, "")
    -- BEGIN Custom Field Join: "%4$s"
    LEFT OUTER JOIN (
    \tSELECT
    \t\tCAST(value AS %5$s) AS %2$s,
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
    instance_eval(&on_prepare)
    self
  end

  def new(*)
    fail "Only subclasses of #{self} should be instanciated." if factory?
    super
  end

  def class_name_for(field)
    "CustomField" << field.split(/[ \-_]/).map { |part| part.gsub(/\W/, '').capitalize }.join
  end
end
