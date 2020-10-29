# encoding: utf-8

require 'spec_helper'
require 'carrierwave/orm/activerecord'
require 'carrierwave_direct/orm/activerecord'

describe CarrierWave::ActiveRecord do
  dbconfig = {
    :adapter => 'sqlite3',
    :database => ':memory:'
  }

  if ActiveRecord::VERSION::MAJOR >= 5
    migration_class = ::ActiveRecord::Migration[5.0]
  else
    migration_class = ::ActiveRecord::Migration
  end

  class OtherTestMigration < migration_class
    def self.up
      create_table :other_parties, :force => true do |t|
        t.column :video, :string
      end
    end

    def self.down
      drop_table :other_parties
    end
  end

  class StandardUploader < CarrierWave::Uploader::Base
  end

  class OtherParty < ActiveRecord::Base
    # mount_uploader :video, StandardUploader
  end

  ActiveRecord::Base.establish_connection(dbconfig)

  # turn off migration output
  ActiveRecord::Migration.verbose = false

  before(:all) { OtherTestMigration.up }
  after(:all) { OtherTestMigration.down }
  after { OtherParty.delete_all }

  describe "class OtherParty < ActiveRecord::Base; mount_uploader :video, StandardUploader; end" do
    $arclass = 0

    let(:party_class) do
      Class.new(OtherParty)
    end

    let(:subject) do
      party = party_class.new
    end

    before do
      # see https://github.com/jnicklas/carrierwave/blob/master/spec/orm/activerecord_spec.rb
      $arclass += 1
      Object.const_set("OtherParty#{$arclass}", party_class)
      party_class.table_name = "other_parties"
    end

    describe "#mount_uploader" do
      it "does not inject CarrierWaveDirect validation into ActiveRecord class" do
        subject.class.mount_uploader :video, StandardUploader

        subject.class.ancestors.should_not include(CarrierWaveDirect::Validations::ActiveModel)
      end

      it "does not modify the class with CarrierWaveDirect-specific methods" do
        subject.class.mount_uploader :video, StandardUploader

        subject.methods.should_not include(:has_video_upload?)
      end
    end
  end
end

