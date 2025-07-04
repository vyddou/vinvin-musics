class Album < ApplicationRecord
  has_one_attached :cover
  has_many :tracks, dependent: :destroy
end
