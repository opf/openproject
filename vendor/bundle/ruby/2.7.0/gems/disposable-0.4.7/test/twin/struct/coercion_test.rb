require "test_helper"
require "disposable/twin/coercion"
require "disposable/twin/property/struct"

class StructCoercionTest < Minitest::Spec
  ExpenseModel = Struct.new(:content)

  class Expense < Disposable::Twin
    feature Property::Struct
    feature Coercion

    property :content do
      property :amount, type: DRY_TYPES_CONSTANT::Float | DRY_TYPES_CONSTANT::Nil
    end

    unnest :amount, from: :content
  end


  it do
    twin = Expense.new( ExpenseModel.new({}) )

    #- direct access, without unnest
    expect(twin.content.amount).must_be_nil
    twin.content.amount = "1.8"
    expect(twin.content.amount).must_equal 1.8
  end

  it "via unnest" do
    twin = Expense.new( ExpenseModel.new({}) )

    expect(twin.amount).must_be_nil
    twin.amount = "1.8"
    expect(twin.amount).must_equal 1.8
  end
end
