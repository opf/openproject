require 'test_helper'

class WriteableTest < MiniTest::Spec
  Credentials = Struct.new(:password, :credit_card) do
    def password=(v)
      raise "don't call me!"
    end
  end

  CreditCard = Struct.new(:name, :number) do
    def number=(v)
      raise "don't call me!"
    end
  end

  class PasswordForm < Disposable::Twin
    feature Setup
    feature Sync

    property :password, writeable: false

    property :credit_card do
      property :name
      property :number, writeable: false
    end
  end

  let (:cred) { Credentials.new("secret", CreditCard.new("Jonny", "0987654321")) }

  let (:twin) { PasswordForm.new(cred) }

  it {
    expect(twin.password).must_equal "secret"
    expect(twin.credit_card.name).must_equal "Jonny"
    expect(twin.credit_card.number).must_equal "0987654321"

    # manual setting on the twin works.
    twin.password = "123"
    expect(twin.password).must_equal "123"

    twin.credit_card.number = "456"
    expect(twin.credit_card.number).must_equal "456"

    twin.sync

    expect(cred.inspect).must_equal '#<struct WriteableTest::Credentials password="secret", credit_card=#<struct WriteableTest::CreditCard name="Jonny", number="0987654321">>'

    # test sync{}.
    hash = {}
    twin.sync do |nested|
      hash = nested
    end

    expect(hash).must_equal("password"=> "123", "credit_card"=>{"name"=>"Jonny", "number"=>"456"})
  }
end
