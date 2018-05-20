require_dependency 'topic_view_item'
module ExportCsvFileExtension
  ACCOUNT = [
    'id',
    'username',
    'created_at',
    'name',
    'last_posted_at',
    'last_seen_at',
    'previous_visit_at',
    'suspended_at',
    'suspended_till',
    'date_of_birth',
    'ip_address',
    'title',
    'locale',
    'registration_ip_address',
    'first_seen_at'
  ]

  PROFILE = [
    'location',
    'website',
    'bio_raw',
  ]

  EMAIL = [
    'email'
  ]

  GOOGLE = [
    'google_user_id',
    'first_name',
    'last_name',
    'email',
    'gender',
    'name',
    'link',
    'profile_link',
    'picture'
  ]

  FACEBOOK = [
    'facebook_user_id',
    'username',
    'first_name',
    'last_name',
    'email',
    'gender',
    'name',
    'avatar_url',
    'about_me',
    'location',
    'website'
  ]

  TWITTER = [
    "screen_name",
    "twitter_user_id",
    "email"
  ]

  INSTAGRAM = [
    'screen_name',
    'instagram_user_id'
  ]

  GITHUB = [
    'screen_name',
    'github_user_id'
  ]

  OAUTH = [
    'uid',
    'provider',
    'email',
    'name'
  ]

  OPEN_ID = [
    "email",
    "url",
  ]

  SSO = [
    "external_id",
    "external_username",
    "external_email",
    "external_name"
  ]

  STATS = [
    'topics_entered',
    'time_read',
    'days_visited',
    'posts_read_count',
    'likes_given',
    'likes_received',
    'topic_reply_count',
    'new_since',
    'read_faq',
    'first_post_created_at',
    'post_count',
    'topic_count'
  ]

  HISTORY = [
    'action',
    'target_user_id',
    'details',
    'created_at',
    'context',
    'ip_address',
    'email',
    'subject',
    'previous_value',
    'new_value',
    'topic_id',
    'post_id',
    'custom_type',
    'category_id'
  ]

  SEARCHES = [
    'term',
    'created_at',
    'ip_address'
  ]

  TOPIC_VIEWS = [
    'title',
    'viewed_at',
    'ip_address'
  ]

  TOPIC_LINK_CLICKS = [
    'url',
    'created_at',
    'ip_address'
  ]

  PROFILE_VIEWS = [
    'username',
    'viewed_at',
    'ip_address'
  ]

  def user_archive_export
    return enum_for(:user_archive_export) unless block_given?

    yield Jobs::ExportCsvFile::HEADER_ATTRS_FOR[@entity]
    user_posts.each { |posts| yield get_user_archive_fields(posts) }

    separator('Account').each { |l| yield l }
    yield ACCOUNT + PROFILE + EMAIL
    yield user_account

    if user_external_accounts_fields.any?
      separator('External Accounts').each { |l| yield l }
      yield user_external_accounts_labels.values
      yield user_external_accounts
    end

    separator('Statistics').each { |l| yield l }
    yield STATS
    yield user_stats

    separator('History').each { |l| yield l }
    yield HISTORY
    user_history.each { |l| yield l }

    separator('Searches').each { |l| yield l }
    yield SEARCHES
    user_searches.each { |l| yield l }

    separator('Topic Views').each { |l| yield l }
    yield TOPIC_VIEWS
    user_topic_views.each { |l| yield l }

    separator('Topic Link Clicks').each { |l| yield l }
    yield TOPIC_LINK_CLICKS
    user_topic_link_clicks.each { |l| yield l }

    separator('Profile Views').each { |l| yield l }
    yield PROFILE_VIEWS
    user_profile_views.each { |l| yield l }
  end

  def get_header
    if @entity === 'user_archive'
      ['Posts']
    else
      super
    end
  end

  def separator(name)
    [["\n"], ["\n"], [name]]
  end

  def user_posts
    Post.includes(topic: :category)
      .where(user_id: @current_user.id)
      .select(:topic_id, :post_number, :raw, :like_count, :reply_count, :created_at)
      .order(:created_at)
      .with_deleted
  end

  def user_account_fields
    ACCOUNT +
    PROFILE.map { |f| "user_profiles.#{f}" } +
    EMAIL.map { |f| "user_emails.#{f}" }
  end

  def user_account
    User.where(id: @current_user.id)
      .joins(:user_profile, :user_emails)
      .select(user_account_fields)
      .first.attributes.values
  end

  def user_external_accounts_fields
    @user_external_accounts_fields ||= begin
      fields = []
      fields.concat GOOGLE.map { |f| "google_user_infos.#{f}" } if GoogleUserInfo.exists?(user_id: @current_user.id)
      fields.concat FACEBOOK.map { |f| "facebook_user_infos.#{f}" } if FacebookUserInfo.exists?(user_id: @current_user.id)
      fields.concat TWITTER.map { |f| "twitter_user_infos.#{f}" } if TwitterUserInfo.exists?(user_id: @current_user.id)
      fields.concat GITHUB.map { |f| "github_user_infos.#{f}" } if GithubUserInfo.exists?(user_id: @current_user.id)
      fields.concat INSTAGRAM.map { |f| "instagram_user_infos.#{f}" } if InstagramUserInfo.exists?(user_id: @current_user.id)
      fields.concat OAUTH.map { |f| "oauth2_user_infos.#{f}" } if Oauth2UserInfo.exists?(user_id: @current_user.id)
      fields.concat OPEN_ID.map { |f| "user_open_ids.#{f}" } if UserOpenId.exists?(user_id: @current_user.id)
      fields.concat SSO.map { |f| "single_sign_on_records.#{f}" } if SingleSignOnRecord.exists?(user_id: @current_user.id)
      fields
    end
  end

  def user_external_accounts_labels
    labels = {}

    @user_external_accounts_fields.each do |f|
      prefix = nil

      case f
      when f.include?('open_ids')
        prefix = 'open_id'
      when f.include?('single_sign_on')
        prefix = 'sso'
      else
        prefix = f.split('_')[0]
      end

      labels[f] = prefix + '_' + f.split('.')[1]
    end

    labels
  end

  def user_external_accounts_select
    @user_external_accounts_fields.map do |f|
      "#{f} AS #{user_external_accounts_labels[f]}"
    end
  end

  def user_external_accounts
    attributes = User.where(id: @current_user.id)
      .joins("
        LEFT JOIN google_user_infos ON google_user_infos.user_id = users.id
        LEFT JOIN facebook_user_infos ON facebook_user_infos.user_id = users.id
        LEFT JOIN twitter_user_infos ON twitter_user_infos.user_id = users.id
        LEFT JOIN github_user_infos ON github_user_infos.user_id = users.id
        LEFT JOIN instagram_user_infos ON instagram_user_infos.user_id = users.id
        LEFT JOIN oauth2_user_infos ON oauth2_user_infos.user_id = users.id
        LEFT JOIN user_open_ids ON user_open_ids.user_id = users.id
        LEFT JOIN single_sign_on_records ON single_sign_on_records.user_id = users.id
      ")
      .select(user_external_accounts_select)
      .first.attributes

    user_external_accounts_labels.values.map { |l| attributes[l] }
  end

  def user_stats
    UserStat.where(user_id: @current_user.id)
      .select(STATS)
      .first.attributes.except("user_id").values
  end

  def user_history
    UserHistory.where(acting_user_id: @current_user.id)
      .select(HISTORY)
      .map do |entry|
        entry.attributes.except("id").map do |k, v|
          if k === "action"
            UserHistory.actions.key(v)
          else
            v
          end
        end
      end
  end

  def user_searches
    SearchLog.where(user_id: @current_user.id)
      .select(SEARCHES)
      .map do |search|
        SEARCHES.map { |k| search.attributes[k] }
      end
  end

  def user_topic_views
    TopicViewItem.where(user_id: @current_user.id)
      .joins("INNER JOIN topics ON topics.id = topic_views.topic_id")
      .select(user_topic_views_fields)
      .map do |view|
        TOPIC_VIEWS.map { |k| view.attributes[k] }
      end
  end

  def user_topic_views_fields
    TOPIC_VIEWS.map do |f|
      f === 'title' ? 'topics.title' : f
    end
  end

  def user_topic_link_clicks
    TopicLinkClick.where(user_id: @current_user.id)
      .joins("INNER JOIN topic_links ON topic_links.id = topic_link_clicks.topic_link_id")
      .select(user_topic_link_clicks_fields)
      .map do |click|
        TOPIC_LINK_CLICKS.map { |k| click.attributes[k] }
      end
  end

  def user_topic_link_clicks_fields
    TOPIC_LINK_CLICKS.map do |f|
      f === 'url' ? 'topic_links.url' : f
    end
  end

  def user_profile_views
    UserProfileView.where(user_id: @current_user.id)
      .joins("INNER JOIN users ON users.id = user_profile_views.user_profile_id")
      .select(user_profile_views_fields)
      .map do |view|
        PROFILE_VIEWS.map { |k| view.attributes[k] }
      end
  end

  def user_profile_views_fields
    PROFILE_VIEWS.map do |f|
      f === 'username' ? 'users.username' : f
    end
  end
end
