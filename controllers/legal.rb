class DiscourseLegal::AdminController < ::ApplicationController
  before_action :ensure_admin

  def index
  end

  def digest_opt_in
    Jobs.enqueue(:digest_opt_in,
      target_users: digest_params[:target_users]
    )

    render json: success_json
  end

  def digest_unsubscribe
    Jobs.enqueue(:digest_unsubscribe,
      target_users: digest_params[:target_users]
    )

    render json: success_json
  end

  def digest_params
    params.permit(:target_users)
  end
end
