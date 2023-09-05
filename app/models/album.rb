class Album < ApplicationRecord
    has_many :songs, dependent: :destroy
end