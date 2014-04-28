class API < Grape::API
  content_type 'hal+json', 'application/hal+json'
  format 'hal+json'

  get do
    "Entry point"
  end

  get :search do
    "search"
  end

  mount WorkPackages::API
  mount Users::API
end
