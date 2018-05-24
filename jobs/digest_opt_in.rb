module Jobs
  class DigestOptIn < Jobs::Base
    def execute(args)
      return if SiteSetting.disable_digest_emails? || SiteSetting.private_email?

      targets = []

      if args[:target_users].present?
        args[:target_users].split(',').each do |username|
          if user = User.find_by(username: username)
            targets.push(user.id)
          end
        end
      else
        targets = digest_subscribers
      end

      targets.each do |user_id|
        Jobs.enqueue(:user_email, type: :digest_opt_in, user_id: user_id)
      end
    end

    def digest_subscribers
      # Users who want to receive digest email within their chosen digest email frequency
      query = User.real
        .not_suspended
        .activated
        .where(staged: false)
        .joins(:user_option, :user_stat)
        .where("user_options.email_digests")
        .where("user_stats.bounce_score < #{SiteSetting.bounce_score_threshold}")
        .where("COALESCE(last_seen_at, '2010-01-01') >= CURRENT_TIMESTAMP - ('1 DAY'::INTERVAL * #{SiteSetting.suppress_digest_email_after_days})")

      # If the site requires approval, make sure the user is approved
      query = query.where("approved OR moderator OR admin") if SiteSetting.must_approve_users?

      query.pluck(:id)
    end

  end

end
