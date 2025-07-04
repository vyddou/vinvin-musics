class Album < ApplicationRecord
  #permet la création d'urls
  include Rails.application.routes.url_helpers

  has_one_attached :cover
  has_many :tracks, dependent: :destroy

  def cover_url
    #génere un url uniquement si une pochette y est attachée
    url_for(self.cover) if self.cover.attached?
  end
end
