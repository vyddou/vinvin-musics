class Track < ApplicationRecord
  # Une piste appartient à un album
  belongs_to :album

  # Contraintes utiles
  validates :title, presence: true
  validates :track_number, allow_nil: true, numericality: { only_integer: true }
  validates :duration_seconds, allow_nil: true, numericality: { only_integer: true }

  # Petit helper pratique : retourne l'artiste, par défaut "Muso" si vide
  def artist_or_default
    artist.presence || "Muso"
  end
end
