class Queries::Principals::Orders::NameOrder < Queries::BaseOrder
  self.model = Principal

  def self.key
    :name
  end

  private

  def order
    ordered = self.model.order_by_name

    if direction == :desc
      ordered = ordered.reverse_order
    end

    ordered
  end
end
