class DiscourseLegal::AdminController < ::ApplicationController
  before_action :ensure_admin

  def index
  end

  def send_consent
    Jobs.enqueue(:send_consent, digest_params.to_h)
    render json: success_json
  end

  def update_attributes
    Jobs.enqueue(:update_attributes, digest_params.to_h)
    render json: success_json
  end

  def digest_params
    params.permit(:target_users, target_attributes: [:email_digests])
  end
end
