module Users
  class UserMapper < Yaks::Mapper

    attributes :id, :login, :firstname, :lastname, :mail
  end
end
