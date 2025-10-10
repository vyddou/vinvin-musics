# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  include Rails.application.routes.url_helpers

  private

  def blob_url(attachment)
    return nil unless attachment&.attached?
    rails_blob_url(attachment, host: request.base_url)  # garantit une URL absolue
  end
end
