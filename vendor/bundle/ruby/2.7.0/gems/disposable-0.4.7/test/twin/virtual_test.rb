require 'test_helper'

class VirtualTest < MiniTest::Spec
  class CreditCardTwin < Disposable::Twin
    include Sync
    property :credit_card_number, virtual: true # no read, no write, it's virtual.
  end

  let (:twin) { CreditCardTwin.new(Object.new) }

  it {
    twin.credit_card_number = "123"

    expect(twin.credit_card_number).must_equal "123"  # this is still readable in the UI.

    twin.sync

    hash = {}
    twin.sync do |nested|
      hash = nested
    end

    expect(hash).must_equal("credit_card_number"=> "123")
  }

  describe "setter should never be called with virtual:true" do
    class Raising < Disposable::Twin
      property :id, virtual: true

      def id=(*)
        raise "i should never be called!"
      end
    end

    it "what" do
      expect(Raising.new(Object.new).id).must_be_nil
    end
  end
end
