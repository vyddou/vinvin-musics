class ApplicationController < ActionController::Base
   # rien d'obligatoire ici pour l'accès public
  private

  # -- Autorise seulement les admins
  def require_admin!
    # current_user est fourni par Devise
    unless current_user&.admin?
      # message + redirection si pas admin
      redirect_to root_path, alert: "Accès réservé à l’admin."
    end
  end
end
