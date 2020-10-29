require 'helper'

describe 'YAML' do
  it 'autoloads classes' do
    expect do
      yaml = "--- !ruby/class Autoloaded::Clazz\n"
      expect(load_with_delayed_visitor(yaml)).to eq(Autoloaded::Clazz)
    end.not_to raise_error
  end

  it 'autoloads the class of a struct' do
    expect do
      yaml = "--- !ruby/class Autoloaded::Struct\n"
      expect(load_with_delayed_visitor(yaml)).to eq(Autoloaded::Struct)
    end.not_to raise_error
  end

  it 'autoloads the class for the instance of a struct' do
    expect do
      yaml = '--- !ruby/struct:Autoloaded::InstanceStruct {}'
      expect(load_with_delayed_visitor(yaml).class).to eq(Autoloaded::InstanceStruct)
    end.not_to raise_error
  end

  it 'autoloads the class of an anonymous struct' do
    expect do
      yaml = "--- !ruby/struct\nn: 1\n"
      object = YAML.load(yaml)
      expect(object).to be_kind_of(Struct)
      expect(object.n).to eq(1)
    end.not_to raise_error
  end

  it 'autoloads the class for the instance' do
    expect do
      yaml = "--- !ruby/object:Autoloaded::InstanceClazz {}\n"
      expect(load_with_delayed_visitor(yaml).class).to eq(Autoloaded::InstanceClazz)
    end.not_to raise_error
  end

  it 'does not throw an uninitialized constant Syck::Syck when using YAML.load with poorly formed yaml' do
    expect { YAML.load(YAML.dump('foo: *bar')) }.not_to raise_error
  end

  def load_with_delayed_visitor(yaml)
    YAML.load_dj(yaml)
  end
end
