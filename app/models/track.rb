class Track < ApplicationRecord
  belongs_to :album
  has_one_attached :audiofile # va récupérer le mp3 correspondant à la track
end
