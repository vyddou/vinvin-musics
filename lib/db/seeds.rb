#Nettoyage de la base de donnée au lancement du seed
puts "Nettoyage de la base de données... Veuillez patienter"
Track.destroy_all
Album.destroy_all
puts "La base de donnée a bien été nettoyée."

puts "La création de l'album et des pistes est en cours...."

#création de l'album
album = Album.create!(
  title: "Simone",
  description: "SIMONE est un voyage musical aux accents Java et électro, où les mots d’un cœur brisé dansent sur les ruines d’un amour envolé. Dix chansons pour raconter l’histoire d’un homme égaré, abandonné par Simone, et qui cherche encore sa voix au creux des machines"
)

#Attache la cover de l'album
album.cover.attach(
  io: File.open(Rails.root.join('lib', 'seed_assets', 'cover.jpg')),
  filename: 'cover.jpg'
)

#Création des piste puis y attache le fichier mp3
tracks_data = [
  { title: "Simone reviens", filename: "1_simone_reviens.mp3" },
  { title: "Fenêtre sur cour", filename: "2_fenetre_sur_cour.mp3" },
  { title: "Encore un sou", filename: "3_encore_un_sou.mp3" },
  { title: "Allez va Simone", filename: "4_allez_va_simone.mp3" },
  { title: "Je rentre", filename: "5_je_rentre.mp3" },
  { title: "Simon", filename: "6_simon.mp3" },
  { title: "Za va pas", filename: "7_za_va_pas.mp3" },
  { title: "A Tataoui", filename: "8_a_tataoui.mp3" },
  { title: "C'est la guerre", filename: "9_c_est_la_guerre.mp3" },
  { title: "Envoyez-moi des lettres", filename: "10_envoyez_moi_des_lettres.mp3" }
]

# Permet de lire la liste
tracks_data.each_with_index do |track_info, index|
  track = album.tracks.create!(
    title: track_info[:title],
    track_number: index + 1
  )

  #récupere les fichier dans le bon dossier
  track.audio_file.attach(
    io: File.open(Rails.root.join('lib', 'seed_assets', track_info[:filename])),
    filename: track_info[:filename]
  )
  puts "Piste '#{track.title}' Créée avec succès."
end

puts "Seed terminée avec succès!"
