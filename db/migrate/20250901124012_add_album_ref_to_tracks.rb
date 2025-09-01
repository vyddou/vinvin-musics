class AddAlbumRefToTracks < ActiveRecord::Migration[7.1]
  def change
    # Ajoute album_id si absent
    unless column_exists?(:tracks, :album_id)
      add_reference :tracks, :album, null: true, foreign_key: true, index: true
    end
  end
end
