require_dependency 'mailers/user_notifications'

class ConsentRenderer < UserNotifications::UserNotificationRenderer
  def protect_against_forgery?
    false
  end
end

module UserNotificationsExtension
  def consent(user, opts = {})
    title = opts['title']

    before = PrettyText.cook(opts['before'], sanitize: false).html_safe

    consent_key = SecureRandom.hex(32)

    PluginStore.set("legal_tools_consent_key_#{opts['field']}", user.id, consent_key)

    consent_url = "#{Discourse.base_url}/email/consent/#{consent_key}"

    html = DigestOptInRenderer.new(Rails.configuration.paths["app/views"]).render(
      template: 'email/consent',
      format: :html,
      locals: {
        title: title,
        before: before,
        button: button,
        after: after,
        consent_url: consent_url
      }
    )

    build_email(
      user.email,
      template: 'user_notifications.consent',
      html_override: html,
      locale: user_locale(user),
      email: user.email
    )
  end
end

module EmailControllerExtension
  def consent
    RateLimiter.new(nil, "consent_#{request.ip}", 10, 1.minute).performed!

    consent_key = PluginStoreRow.find_by(value: params[:key])
    raise Discourse::NotFound unless key

    user = User.find(key['key'])
    field = key['plugin_name'].split('_').last

    user.custom_fields[field] = true
    user.save_custom_fields(true)

    redirect_to '/'
  end
end

class UserNotifications
  prepend UserNotificationsExtension
end

require_dependency 'controllers/email_controller'
class EmailController
  skip_before_action :verify_authenticity_token, only: [:consent]
  prepend EmailControllerExtension
end
