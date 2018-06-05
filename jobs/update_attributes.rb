module Jobs
  class DigestUnsubscribe < Jobs::Base
    def execute(args)
      return if SiteSetting.disable_digest_emails? || SiteSetting.private_email?

      targets = []

      if args[:target_users].present
        args[:target_users].each do |username|
          targets.push(User.find_by(username: username))
        end
      else
        targets = havent_opted_in
      end

      targets.each do |user_id|
        user = User.find(user_id)
        user.user_option.update_columns(email_digests: false)
      end
    end

    def havent_opted_in
      query = User.real
        .not_suspended
        .activated
        .where(staged: false)
        .joins(:user_option, :user_custom_fields)
        .where("user_options.email_digests")
        .where("user_custom_fields.name = 'opted_into_digest' AND 'user_custom_fields.value' IS NULL")

      query.pluck(:id)
    end
  end
end
