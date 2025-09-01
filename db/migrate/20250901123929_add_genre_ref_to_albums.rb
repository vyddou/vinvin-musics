class AddGenreRefToAlbums < ActiveRecord::Migration[7.1]
  def change
    # On n'ajoute la colonne que si elle n'existe pas déjà (idempotent)
    unless column_exists?(:albums, :genre_id)
      # add_reference crée genre_id + index, et foreign_key: true ajoute la contrainte SQL
      add_reference :albums, :genre, null: true, foreign_key: true, index: true
      # null: true = on autorise temporairement NULL (plus souple pour migrer)
    end
  end
end
