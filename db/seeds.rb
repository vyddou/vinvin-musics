# db/seeds.rb

ActiveRecord::Base.transaction do
  # On nettoie dans un ordre logique (pistes -> albums -> genres)
  Track.delete_all    # supprime toutes les pistes
  Album.delete_all    # supprime tous les albums
  Genre.delete_all    # supprime tous les genres

  # 1) Genres de base (Muso pourra choisir/ajouter plus tard)
  %w[Variété Rock Punk Electro Jazz].each do |g|
    Genre.find_or_create_by!(name: g)  # idempotent : pas de doublons si on relance
  end

  # 2) On choisit le genre de l’album "Simone" (ici : Variété)
  variete = Genre.find_by!(name: "Variété")

  # 3) On crée l’album "Simone"
  simone = Album.create!(
    title: "Simone",                  # titre de l’album
    cover_url: "/covers/cover.png",   # pochette stockée dans public/covers/cover.png
    release_year: 2025,               # adapte si besoin
    genre: variete                    # association au genre Variété
  )
  puts "Album 'Simone' id=#{simone.id}"

  # 4) Liste des 10 titres (durées fictives OK pour l’instant)
  tracks = [
    { title: "Simone reviens",          file: "01-simone-reviens.mp3",        duration: 180 },
    { title: "Fenêtre sur cour",        file: "02-fenetre-sur-cour.mp3",      duration: 200 },
    { title: "Encore un sou",           file: "03-encore-un-sou.mp3",         duration: 190 },
    { title: "Allez va Simone",         file: "04-allez-va-simone.mp3",       duration: 210 },
    { title: "Je rentre",               file: "05-je-rentre.mp3",             duration: 175 },
    { title: "Simon",                   file: "06-simon.mp3",                 duration: 185 },
    { title: "Ça va pas",               file: "07-za-va-pas.mp3",             duration: 195 },
    { title: "À Tataoui",               file: "08-a-tataoui.mp3",             duration: 200 },
    { title: "C’est la guerre",         file: "09-cest-la-guerre.mp3",        duration: 220 },
    { title: "Envoyez-moi des lettres", file: "10-envoyez-moi-des-lettres.mp3", duration: 240 }
  ]

  # 5) Création des pistes associées à l’album
  tracks.each_with_index do |t, i|
    Track.create!(
      title: t[:title],                       # nom de la piste
      artist: "Muso",                         # nom d’artiste
      duration_seconds: t[:duration],         # durée (fictive pour l’instant)
      audio_url: "/audio/#{t[:file]}",        # chemin public vers le mp3
      cover_url: simone.cover_url,            # on réutilise la cover de l’album
      track_number: i + 1,                    # n° de piste (1..10)
      album: simone                           # association à l’album "Simone"
    )
  end
end

puts "✅ Seeds OK :
- Genres : #{Genre.count}
- Albums : #{Album.count}
- Tracks : #{Track.count}"
