class Genre < ApplicationRecord
  # Un genre possède plusieurs albums
  has_many :albums, dependent: :nullify  # si on supprime un genre, on garde les albums (genre_id = NULL)

  # Le nom doit être présent et unique
  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
