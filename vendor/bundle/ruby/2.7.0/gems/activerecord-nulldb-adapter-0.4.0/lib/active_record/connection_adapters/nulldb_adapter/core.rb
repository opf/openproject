class ActiveRecord::ConnectionAdapters::NullDBAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter

  # A convenience method for integratinginto RSpec.  See README for example of
  # use.
  def self.insinuate_into_spec(config)
    config.before :all do
      ActiveRecord::Base.establish_connection(:adapter => :nulldb)
    end

    config.after :all do
      ActiveRecord::Base.establish_connection(:test)
    end
  end

  # Recognized options:
  #
  # [+:schema+] path to the schema file, relative to Rails.root
  # [+:table_definition_class_name+] table definition class
  # (e.g. ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition for Postgres) or nil.
  def initialize(config={})
    @log            = StringIO.new
    @logger         = Logger.new(@log)
    @last_unique_id = 0
    @tables         = {'schema_info' => new_table_definition(nil)}
    @indexes        = Hash.new { |hash, key| hash[key] = [] }
    @schema_path    = config.fetch(:schema){ "db/schema.rb" }
    @config         = config.merge(:adapter => :nulldb)
    super *initialize_args
    @visitor ||= Arel::Visitors::ToSql.new self if defined?(Arel::Visitors::ToSql)

    if config[:table_definition_class_name]
      ActiveRecord::ConnectionAdapters::NullDBAdapter.send(:remove_const, 'TableDefinition')
      ActiveRecord::ConnectionAdapters::NullDBAdapter.const_set('TableDefinition',
        self.class.const_get(config[:table_definition_class_name]))
    end

    register_types unless NullDB::LEGACY_ACTIVERECORD || \
                          ActiveRecord::VERSION::MAJOR < 4
  end

  # A log of every statement that has been "executed" by this connection adapter
  # instance.
  def execution_log
    (@execution_log ||= [])
  end

  # A log of every statement that has been "executed" since the last time
  # #checkpoint! was called, or since the connection was created.
  def execution_log_since_checkpoint
    checkpoint_index = @execution_log.rindex(Checkpoint.new)
    checkpoint_index = checkpoint_index ? checkpoint_index + 1 : 0
    @execution_log[(checkpoint_index..-1)]
  end

  # Inserts a checkpoint in the log.  See also #execution_log_since_checkpoint.
  def checkpoint!
    self.execution_log << Checkpoint.new
  end

  def adapter_name
    "NullDB"
  end

  def supports_migrations?
    true
  end

  def create_table(table_name, options = {})
    table_definition = new_table_definition(self, table_name, options.delete(:temporary), options)

    unless options[:id] == false
      table_definition.primary_key(options[:primary_key] || "id")
    end

    yield table_definition if block_given?

    @tables[table_name] = table_definition
  end

  def add_index(table_name, column_names, options = {})
    column_names = Array.wrap(column_names).map(&:to_s)
    index_name, index_type, ignore = add_index_options(table_name, column_names, options)
    @indexes[table_name] << IndexDefinition.new(table_name, index_name, (index_type == 'UNIQUE'), column_names, [], [])
  end

  unless instance_methods.include? :add_index_options
    def add_index_options(table_name, column_name, options = {})
      column_names = Array.wrap(column_name)
      index_name   = index_name(table_name, :column => column_names)

      if Hash === options # legacy support, since this param was a string
        index_type = options[:unique] ? "UNIQUE" : ""
        index_name = options[:name].to_s if options.key?(:name)
      else
        index_type = options
      end

      if index_name.length > index_name_length
        raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' is too long; the limit is #{index_name_length} characters"
      end
      if index_name_exists?(table_name, index_name, false)
        raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' already exists"
      end
      index_columns = quoted_columns_for_index(column_names, options).join(", ")

      [index_name, index_type, index_columns]
    end
  end

  unless instance_methods.include? :index_name_exists?
    def index_name_exists?(table_name, index_name, default)
      return default unless respond_to?(:indexes)
      index_name = index_name.to_s
      indexes(table_name).detect { |i| i.name == index_name }
    end
  end

  def add_fk_constraint(*args)
    # NOOP
  end

  def add_pk_constraint(*args)
    # NOOP
  end

  def enable_extension(*)
    # NOOP
  end

  # Retrieve the table names defined by the schema
  def tables
    @tables.keys.map(&:to_s)
  end

  def views
    [] # TODO: Implement properly if needed - This is new method in rails
  end

  # Retrieve table columns as defined by the schema
  def columns(table_name, name = nil)
    if @tables.size <= 1
      ActiveRecord::Migration.verbose = false
      schema_path = if Pathname(@schema_path).absolute?
                      @schema_path
                    else
                      File.join(NullDB.configuration.project_root, @schema_path)
                    end
      Kernel.load(schema_path)
    end

    if table = @tables[table_name]
      table.columns.map do |col_def|
        col_args = new_column_arguments(col_def)
        ActiveRecord::ConnectionAdapters::NullDBAdapter::Column.new(*col_args)
      end
    else
      []
    end
  end

  # Retrieve table indexes as defined by the schema
  def indexes(table_name, name = nil)
    @indexes[table_name]
  end

  def execute(statement, name = nil)
    self.execution_log << Statement.new(entry_point, statement)
    NullObject.new
  end

  def exec_query(statement, name = 'SQL', binds = [], options = {})
    self.execution_log << Statement.new(entry_point, statement)
    EmptyResult.new
  end

  def select_rows(statement, name = nil, binds = [])
    [].tap do
      self.execution_log << Statement.new(entry_point, statement)
    end
  end

  def insert(statement, name = nil, primary_key = nil, object_id = nil, sequence_name = nil, binds = [])
    (object_id || next_unique_id).tap do
      with_entry_point(:insert) do
        super(statement, name, primary_key, object_id, sequence_name)
      end
    end
  end
  alias :create :insert

  def update(statement, name=nil, binds = [])
    with_entry_point(:update) do
      super(statement, name)
    end
  end

  def delete(statement, name=nil, binds = [])
    with_entry_point(:delete) do
      super(statement, name).size
    end
  end

  def select_all(statement, name=nil, binds = [], options = {})
    with_entry_point(:select_all) do
      super(statement, name)
    end
  end

  def select_one(statement, name=nil, binds = [])
    with_entry_point(:select_one) do
      super(statement, name)
    end
  end

  def select_value(statement, name=nil, binds = [])
    with_entry_point(:select_value) do
      super(statement, name)
    end
  end

  def select_values(statement, name=nil)
    with_entry_point(:select_values) do
      super(statement, name)
    end
  end

  def primary_key(table_name)
    columns(table_name).detect { |col| col.sql_type == :primary_key }.try(:name)
  end

  protected

  def select(statement, name = nil, binds = [])
    EmptyResult.new.tap do |r|
      r.bind_column_meta(columns_for(name))
      self.execution_log << Statement.new(entry_point, statement)
    end
  end

  private

  def columns_for(table_name)
    table_meta = @tables[table_name]
    return [] unless table_meta
    table_meta.columns
  end

  def next_unique_id
    @last_unique_id += 1
  end

  def with_entry_point(method)
    if entry_point.nil?
      with_thread_local_variable(:entry_point, method) do
        yield
      end
    else
      yield
    end
  end

  def entry_point
    Thread.current[:entry_point]
  end

  def with_thread_local_variable(name, value)
    old_value = Thread.current[name]
    Thread.current[name] = value
    begin
      yield
    ensure
      Thread.current[name] = old_value
    end
  end

  def includes_column?
    false
  end

  def new_table_definition(adapter = nil, table_name = nil, is_temporary = nil, options = {})
    case ::ActiveRecord::VERSION::MAJOR
    when 6
      TableDefinition.new(self, table_name, temporary: is_temporary, options: options.except(:id))
    when 5
      TableDefinition.new(table_name, is_temporary, options.except(:id), nil)
    when 4
      TableDefinition.new(native_database_types, table_name, is_temporary, options)
    when 2,3
      TableDefinition.new(adapter)
    else
      raise "Unsupported ActiveRecord version #{::ActiveRecord::VERSION::STRING}"
    end
  end

  def new_column_arguments(col_def)
    args_with_optional_cast_type(col_def)
  end

  def args_with_optional_cast_type(col_def)
    default_column_arguments(col_def).tap do |args|
      if defined?(ActiveRecord::ConnectionAdapters::SqlTypeMetadata)
        meta = ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(sql_type: col_def.type)
        args.insert(2, meta_with_limit!(meta, col_def))
      elsif initialize_column_with_cast_type?
        args.insert(2, meta_with_limit!(lookup_cast_type(col_def.type), col_def))
      else
        args[2] = args[2].to_s + "(#{col_def.limit})" if col_def.limit
      end
    end
  end

  def meta_with_limit!(meta, col_def)
    meta.instance_variable_set('@limit', col_def.limit)
    meta
  end

  def default_column_arguments(col_def)
    if ActiveRecord::VERSION::MAJOR >= 5
      [
        col_def.name.to_s,
        col_def.default,
        col_def.null.nil? || col_def.null # cast  [false, nil, true] => [false, true, true], other adapters default to null=true 
      ]
    else
      [
        col_def.name.to_s,
        col_def.default,
        col_def.type,
        col_def.null.nil? || col_def.null # cast  [false, nil, true] => [false, true, true], other adapters default to null=true 
      ]
    end
  end

  def initialize_column_with_cast_type?
    ::ActiveRecord::VERSION::MAJOR == 4 && ::ActiveRecord::VERSION::MINOR >= 2
  end

  def initialize_args
    return [nil, @logger, @config] if ActiveRecord::VERSION::MAJOR > 3
    [nil, @logger]
  end

  # 4.2 introduced ActiveRecord::Type
  # https://github.com/rails/rails/tree/4-2-stable/activerecord/lib/active_record
  def register_types
    if ActiveRecord::VERSION::MAJOR < 5
      type_map.register_type(:primary_key, ActiveRecord::Type::Integer.new)
    else      
      require 'active_model/type'
      ActiveRecord::Type.register(
        :primary_key,
        ActiveModel::Type::Integer,
        adapter: adapter_name,
        override: true
      )
    end
  end
end
