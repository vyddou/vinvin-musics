# db/migrate/XXXXXXXXXX_add_cover_url_and_release_year_to_albums.rb
class AddCoverUrlAndReleaseYearToAlbums < ActiveRecord::Migration[7.1]
  def change
    # On ajoute cover_url (string) à la table albums,
    # seulement si elle n'existe pas déjà (évite les erreurs si relancé)
    add_column :albums, :cover_url, :string unless column_exists?(:albums, :cover_url)

    # On s'assure que release_year existe (entier, optionnel)
    add_column :albums, :release_year, :integer unless column_exists?(:albums, :release_year)
  end
end
