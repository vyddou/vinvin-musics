class Album < ApplicationRecord
  # Un album appartient à un genre (variété, rock, ...)
  belongs_to :genre

  # Un album contient plusieurs pistes
  has_many :tracks, -> { order(:track_number) }, dependent: :destroy

  # Contraintes de base
  validates :title, presence: true
  validates :release_year, allow_nil: true, numericality: { only_integer: true }
end
