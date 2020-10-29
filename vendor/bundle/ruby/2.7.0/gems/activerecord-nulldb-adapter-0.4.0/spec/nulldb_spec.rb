require 'rubygems'

# Optional simplecov loading
begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError
end

require 'active_record'
require 'active_record/version'
$: << File.join(File.dirname(__FILE__), "..", "lib")

if ActiveRecord::VERSION::MAJOR > 2
  require 'rspec' # rspec 2
else
  require 'spec' # rspec 1
end

require 'nulldb_rspec'

class Employee < ActiveRecord::Base
  after_save :on_save_finished

  def on_save_finished
  end
end

class TablelessModel < ActiveRecord::Base
end

NullDB.configure {|ndb| ndb.project_root = 'Rails.root'}

describe "NullDB with no schema pre-loaded" do
  before :each do
    allow( Kernel ).to receive :load
    allow( ActiveRecord::Migration ).to receive :verbose=
  end

  it "should load Rails.root/db/schema.rb if no alternate is specified" do
    ActiveRecord::Base.establish_connection :adapter => :nulldb
    expect( Kernel ).to receive(:load).with("Rails.root/db/schema.rb")
    ActiveRecord::Base.connection.columns('schema_info')
  end

  it "should load the specified schema relative to Rails.root" do
    expect( Kernel ).to receive(:load).with("Rails.root/foo/myschema.rb")
    ActiveRecord::Base.establish_connection :adapter => :nulldb,
                                            :schema => "foo/myschema.rb"
    ActiveRecord::Base.connection.columns('schema_info')
  end

  it "should suppress migration output" do
    expect( ActiveRecord::Migration).to receive(:verbose=).with(false)
    ActiveRecord::Base.establish_connection :adapter => :nulldb,
                                            :schema => "foo/myschema.rb"
    ActiveRecord::Base.connection.columns('schema_info')
  end

  it "should allow creating a table without passing a block" do
    ActiveRecord::Base.establish_connection :adapter => :nulldb
    ActiveRecord::Schema.define do
      create_table(:employees)
    end
  end
end

describe "NullDB" do
  before :all do
    ActiveRecord::Base.establish_connection :adapter => :nulldb
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Schema.define do
      create_table(:employees) do |t|
        t.string  :name, null: false, limit: 50
        t.date    :hire_date
        t.integer :employee_number
        t.decimal :salary
      end

      create_table(:employees_widgets, :id => false, :force => true) do |t|
        t.integer :employee_id
        t.integer :widget_id
      end

      add_index "employees", :name, :name => "index_employees_on_name"
      add_index "employees", ["employee_number"], :name => "index_employees_on_employee_number", :unique => true
      add_index "employees_widgets", ["employee_id", "widget_id"], :name => "my_index"

      add_fk_constraint "foo", "bar", "baz", "buz", "bungle"
      add_pk_constraint "foo", "bar", {}, "baz", "buz"
    end
  end

  before :each do
    @employee =  Employee.new(:name           => "John Smith",
                             :hire_date       => Date.civil(2000, 1, 1),
                             :employee_number => 42,
                             :salary          => 56000.00)
  end

  it "should set the @config instance variable so plugins that assume its there can use it" do
    expect( Employee.connection.instance_variable_get(:@config)[:adapter]).to eq :nulldb
  end

  it "should enable instantiation of AR objects without a database" do
    expect( @employee ).to be_a_kind_of(ActiveRecord::Base)
  end

  it "should remember columns defined in migrations" do
    should_have_column(Employee, :name, :string)
    should_have_column(Employee, :hire_date, :date)
    should_have_column(Employee, :employee_number, :integer)
    should_have_column(Employee, :salary, :decimal)
  end

  it 'should have limit on name' do
    expect(Employee.columns_hash['name'].limit).to eq 50
  end

  it "should return true on nullable field" do
    expect(Employee.columns_hash['salary'].null).to be true
  end

  it "should return false on non-nullable field" do
    expect(Employee.columns_hash['name'].null).to be false
  end

  it "should return the appropriate primary key" do
    expect( ActiveRecord::Base.connection.primary_key('employees') ).to eq 'id'
  end

  it "should return a nil primary key on habtm" do
    expect( ActiveRecord::Base.connection.primary_key('employees_widgets') ).to eq nil
  end

  it "should return an empty array of columns for a table-less model" do
    expect( TablelessModel.columns).to eq []
  end

  it "should enable simulated saving of AR objects" do
    expect{ @employee.save! }.to_not raise_error
  end

  it "should enable AR callbacks during simulated save" do
    expect( @employee ).to receive :on_save_finished
    @employee.save
  end

  it "should enable simulated deletes of AR objects" do
    expect{ @employee.destroy }.to_not raise_error
  end

  it "should enable simulated creates of AR objects" do
    emp = Employee.create(:name => "Bob Jones")
    expect( emp.name ).to eq "Bob Jones"
  end

  it "should generate new IDs when inserting unsaved objects" do
    cxn = Employee.connection
    id1 = cxn.insert("some sql", "SomeClass Create", "id", nil, nil)
    id2 = cxn.insert("some sql", "SomeClass Create", "id", nil, nil)
    expect( id2 ).to eq (id1 + 1)
  end

  it "should re-use object ID when inserting saved objects" do
    cxn = Employee.connection
    id1 = cxn.insert("some sql", "SomeClass Create", "id", 23, nil)
    expect( id1 ).to eq 23
  end

  it "should log executed SQL statements" do
    cxn = Employee.connection
    exec_count = cxn.execution_log.size
    @employee.save!
    expect( cxn.execution_log.size ).to eq (exec_count + 1)
  end

  it "should have the adapter name 'NullDB'" do
    expect( Employee.connection.adapter_name ).to eq "NullDB"
  end

  it "should support migrations" do
    expect( Employee.connection.supports_migrations? ).to eq true
  end

  it "should always have a schema_info table definition" do
    expect( Employee.connection.tables ).to include "schema_info"
  end

  it "should return an empty array from #select" do
    result = Employee.connection.select_all("who cares", "blah")
    expect( result ).to eq []
  end

  it "should provide a way to set log checkpoints" do
    cxn = Employee.connection
    @employee.save!
    expect( cxn.execution_log_since_checkpoint.size ).to be > 0

    cxn.checkpoint!
    expect( cxn.execution_log_since_checkpoint.size ).to eq 0

    @employee.salary = @employee.salary + 1
    @employee.save!
    expect( cxn.execution_log_since_checkpoint.size ).to eq 1
  end

  def should_contain_statement(cxn, entry_point)
    expect( cxn.execution_log_since_checkpoint).to \
      include(ActiveRecord::ConnectionAdapters::NullDBAdapter::Statement.new(entry_point))
  end

  def should_not_contain_statement(cxn, entry_point)
    expect( cxn.execution_log_since_checkpoint ).to_not \
      include(ActiveRecord::ConnectionAdapters::NullDBAdapter::Statement.new(entry_point))
  end

  it "should tag logged statements with their entry point" do
    cxn = Employee.connection

    should_not_contain_statement(cxn, :insert)
    @employee.save
    should_contain_statement(cxn, :insert)

    cxn.checkpoint!
    should_not_contain_statement(cxn, :update)
    @employee.salary = @employee.salary + 1
    @employee.save
    should_contain_statement(cxn, :update)

    cxn.checkpoint!
    should_not_contain_statement(cxn, :delete)
    @employee.destroy
    should_contain_statement(cxn, :delete)

    cxn.checkpoint!
    should_not_contain_statement(cxn, :select_all)
    Employee.all.each do |emp|; end
    should_contain_statement(cxn, :select_all)

    cxn.checkpoint!
    should_not_contain_statement(cxn, :select_value)
    Employee.count_by_sql("frobozz")
    should_contain_statement(cxn, :select_value)

    cxn.checkpoint!
    should_not_contain_statement(cxn, :select_values)
    cxn.select_values("")
    should_contain_statement(cxn, :select_values)
  end

  it "should allow #finish to be called on the result of #execute" do
    Employee.connection.execute("blah").finish
  end

  it "should #to_a return empty array on the result of #execute" do
    result = Employee.connection.execute("blah")
    expect( result.to_a ).to be_a Array
    expect( result.to_a ).to be_empty
  end

  def should_have_column(klass, col_name, col_type)
    col = klass.columns_hash[col_name.to_s]
    expect(col.sql_type.to_s.gsub(/\([0-9]+\)/, "").to_sym).to eq col_type
  end


  it "should support adding indexes" do
    expect( Employee.connection.indexes('employees').size ).to eq 2
    expect( Employee.connection.indexes('employees_widgets').size ).to eq 1
  end

  it "should support unique indexes" do
    expect( Employee.connection.indexes('employees').detect{|idx| idx.columns == ["name"]}.unique ).to eq false
    expect( Employee.connection.indexes('employees').detect{|idx| idx.columns == ["employee_number"]}.unique ).to eq true
  end

  it "should support multi-column indexes" do
    expect( Employee.connection.indexes('employees_widgets').first.columns).to eq ["employee_id", "widget_id"]
  end

  it "should support custom index names" do
    expect( Employee.connection.indexes('employees_widgets').first.name ).to eq 'my_index'
  end

  it 'should handle ActiveRecord::ConnectionNotEstablished' do
    expect( ActiveRecord::Base ).to receive(:connection_pool).and_raise(ActiveRecord::ConnectionNotEstablished)
    expect { NullDB.nullify }.to_not raise_error
  end

  it 'should handle count queries' do 
    expect(Employee.count).to eql(0)
  end
end

# need a fallback db for contextual nullification
ActiveRecord::Base.configurations['test'] = {'adapter' => 'nulldb'}

describe NullDB::RSpec::NullifiedDatabase do
  describe 'have_executed rspec matcher' do
    before(:all) do
      ActiveRecord::Schema.define do
        create_table(:employees)
      end
    end

    include NullDB::RSpec::NullifiedDatabase

    before { NullDB.checkpoint }

    it 'passes if an execution was made' do
      expect( Employee.connection ).to receive(:insert)
      allow( Kernel ).to receive :load
      Employee.create
    end
  end

  describe '.globally_nullify_database' do
    it 'nullifies the database' do
      expect( NullDB::RSpec::NullifiedDatabase ).to respond_to(:nullify_database)
      expect( NullDB::RSpec::NullifiedDatabase ).to receive(:nullify_database)
      NullDB::RSpec::NullifiedDatabase.globally_nullify_database
    end
  end
end


describe 'adapter-specific extensions' do
  before(:all) do
    ActiveRecord::Base.establish_connection :adapter => :nulldb
    ActiveRecord::Migration.verbose = false
  end

  it "supports 'enable_extension' in the schema definition" do
    expect{
      ActiveRecord::Schema.define do
        enable_extension "plpgsql"
      end
    }.to_not raise_error
  end

  if ActiveRecord::VERSION::MAJOR > 4
    it 'registers a primary_key type' do
      expect(ActiveRecord::Type.lookup(:primary_key, adapter: 'NullDB'))
        .to be_a(ActiveModel::Type::Integer)
    end
  end
end

describe ActiveRecord::ConnectionAdapters::NullDBAdapter::EmptyResult do
  it "should return an empty array from #cast_values" do
    result = described_class.new
    expect( result.cast_values ).to be_a Array
    expect( result.cast_values ).to be_empty
  end
end
