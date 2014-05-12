module Versions
  class VersionMapper < Yaks::Mapper
    link :self, '/api/v3/versions/{id}'

    attributes :id
  end
end
