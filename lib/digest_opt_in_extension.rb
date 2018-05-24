require_dependency 'mailers/user_notifications'

class DigestOptInRenderer < UserNotifications::UserNotificationRenderer
  def protect_against_forgery?
    false
  end
end

module UserNotificationsExtension
  def digest_opt_in(user, opts = {})
    title = I18n.t("user_notifications.digest_opt_in.title")

    message = PrettyText.cook(
      I18n.t('user_notifications.digest_opt_in.description', site_name: SiteSetting.title),
      sanitize: false
    ).html_safe

    subscribe_key = UnsubscribeKey.create_key_for(user, "digest_opt_in")

    subscribe_url = "#{Discourse.base_url}/email/digest-opt-in/#{subscribe_key}"

    html = DigestOptInRenderer.new(Rails.configuration.paths["app/views"]).render(
      template: 'email/digest_opt_in',
      format: :html,
      locals: {
        title: title,
        message: message,
        subscribe_url: subscribe_url
      }
    )

    build_email(
      user.email,
      template: 'user_notifications.digest_opt_in',
      html_override: html,
      locale: user_locale(user),
      email: user.email,
      subscribe_url: subscribe_url,
    )
  end
end

module EmailControllerExtension
  def digest_opt_in
    RateLimiter.new(nil, "unsubscribe_#{request.ip}", 10, 1.minute).performed!

    key = UnsubscribeKey.find_by(key: params[:key])
    raise Discourse::NotFound unless key && key.user

    user = key.user
    user.custom_fields['opted_into_digest'] = true
    user.save_custom_fields(true)

    redirect_to '/'
  end
end

class UserNotifications
  prepend UserNotificationsExtension
end

require_dependency 'controllers/email_controller'
class EmailController
  skip_before_action :verify_authenticity_token, only: [:digest_opt_in]
  prepend EmailControllerExtension
end
