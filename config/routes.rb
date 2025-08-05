Rails.application.routes.draw do
  # API pour l'album
  namespace :api do
    namespace :v1 do
      resources :albums, only: [:index]
    end
  end

  # Page d’accueil Vue + Rails
  root "pages#home"

  # healthcheck (optionnel)
  get "up" => "rails/health#show", as: :rails_health_check
end
