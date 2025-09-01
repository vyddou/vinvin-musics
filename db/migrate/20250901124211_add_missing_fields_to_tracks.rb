# db/migrate/XXXXXXXXXX_add_missing_fields_to_tracks.rb
class AddMissingFieldsToTracks < ActiveRecord::Migration[7.1]
  def change
    # -----------------------------
    # Colonnes de base pour Track
    # -----------------------------

    # string : nom de l'artiste (ex: "Muso")
    add_column :tracks, :artist, :string unless column_exists?(:tracks, :artist)

    # integer : durée en secondes (optionnelle)
    add_column :tracks, :duration_seconds, :integer unless column_exists?(:tracks, :duration_seconds)

    # string : chemin/URL du fichier audio
    add_column :tracks, :audio_url, :string unless column_exists?(:tracks, :audio_url)

    # string : chemin/URL de la pochette (souvent héritée de l'album)
    add_column :tracks, :cover_url, :string unless column_exists?(:tracks, :cover_url)

    # integer : numéro de piste dans l'album
    add_column :tracks, :track_number, :integer unless column_exists?(:tracks, :track_number)

    # Sécurité : s'assurer qu'on a bien la référence d'album (si jamais absente)
    unless column_exists?(:tracks, :album_id)
      add_reference :tracks, :album, null: true, foreign_key: true, index: true
    end
  end
end
