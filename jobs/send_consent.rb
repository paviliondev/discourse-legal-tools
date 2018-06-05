module Jobs
  class SendConsent < Jobs::Base
    def execute(args)
      targets = []

      if args[:target_users].present?
        args[:target_users].split(',').each do |username|
          if user = User.find_by(username: username)
            targets.push(user.id)
          end
        end
      end

      if args[:target_attributes]
        target_attributes_users.each do |user_id|
          targets.push(user_id)
        end
      end

      targets.each do |user_id|
        Jobs.enqueue(:user_email, type: :digest_opt_in, user_id: user_id)
      end
    end

    def target_attributes_users(target_attributes)
      users = User.real.not_suspended.activated.where(staged: false)

      if target_attributes[:email_digests]
        users = users.joins(:user_option).where("user_options.email_digests")
      end

      users = users.where("approved OR moderator OR admin") if SiteSetting.must_approve_users?

      users.pluck(:id)
    end
  end
end
