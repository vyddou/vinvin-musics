class Track < ApplicationRecord
   include Rails.application.routes.url_helpers # Important pour créer les URLs

  belongs_to :album
  has_one_attached :audio_file # va récupérer le mp3 correspondant à la track

  def audio_file_url
    #genere l'url uniquement si un fichier audio est attaché
    url_for(self.audio_file) if self.audio_file.attached?
  end
end
