# db/seeds.rb

ActiveRecord::Base.transaction do
  Track.delete_all
  Genre.delete_all

  # Genre = nom de l'album
  album = Genre.find_or_create_by!(name: "Simone")

  # Les 10 titres de l’album Simone
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

  tracks.each_with_index do |t, i|
    Track.create!(
      title: t[:title],
      artist: "Muso",                           # nom de scène
      duration_seconds: t[:duration],
      audio_url: "/audio/#{t[:file]}",
      cover_url: "/covers/cover.png",           # pochette commune
      track_number: i + 1,
      genre: album
    )
  end
end

puts "✅ Seed importée : Album 'Simone' (#{Track.count} titres)"
