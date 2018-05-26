require_dependency 'topic_view_item'

module ExtendedDownloadControllerExtension
  private def export_params
    if admin_user_archive
      @_export_params ||= begin
        params.require(:entity)
        params.permit(:entity, args: [:user_id]).to_h
      end
    else
      super
    end
  end

  private def admin_user_archive
    params[:entity] === 'admin_user_archive'
  end
end


module ExtendedDownloadGuardianExtension
  def can_export_entity?(entity)
    if entity == "user_archive" || entity == 'admin_user_archive'
      return false unless @user

      if entity == 'user_archive'
        if SiteSetting.legal_extended_user_download
          return true if admin_extended_user_download
          has_not_created_export_today
        else
          return true if is_staff?
          has_not_created_export_today
        end
      elsif entity == 'admin_user_archive'
        admin_extended_user_download
      end
    else
      super
    end
  end

  def has_not_created_export_today
    UserExport.where(user_id: @user.id, created_at: (Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)).count == 0
  end

  def admin_extended_user_download
    case SiteSetting.legal_extended_user_download_admin
    when 'disabled'
      false
    when 'admins_only'
      is_admin?
    when 'admins_and_staff'
      is_staff?
    end
  end
end

module ExtendedDownloadExportExtension
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

  AUTH_TOKEN = [
    "user_agent",
    "client_ip",
    "seen_at"
  ]

  AUTH_TOKEN_LOGS = [
    "action",
    "client_ip",
    "user_agent",
    "created_at"
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

  ACTIONS = [
    'action_type',
    'target_topic_id',
    'target_post_id',
    'acting_user_id',
    'created_at'
  ]

  ACTION_LABELS = {
    1 => 'Like',
    2 => 'Was Liked',
    3 => 'Bookmark',
    4 => 'New Topic',
    5 => 'Reply',
    6 => 'Response',
    7 => 'Mention',
    9 => 'Quote',
    11 => 'Edit',
    12 => 'New Private Message',
    13 => 'Got Private Message',
    14 => 'Pending',
    15 => 'Solved',
    16 => 'Assigned'
  }

  def user_archive_export(&block)
    return enum_for(:user_archive_export) unless block_given?

    if SiteSetting.legal_extended_user_download
      user_archive_export_extended(block)
    else
      super
    end
  end

  def admin_user_archive_export(&block)
    return enum_for(:admin_user_archive_export) unless block_given?

    if SiteSetting.legal_extended_user_download_admin
      user_archive_export_extended(block)
    else
      raise Discourse::InvalidAccess.new(legal_extended_user_download_admin)
    end
  end

  def archive_user
    @archive_user ||= begin
      if @entity === 'user_archive'
        @current_user
      else
        User.find_by(id: @extra[:user_id])
      end
    end
  end

  def get_header
    if (@entity === 'user_archive' && SiteSetting.legal_extended_user_download) ||
       (@entity === 'admin_user_archive' && SiteSetting.legal_extended_user_download_admin)
      extended_header
    else
      super
    end
  end

  def extended_header
    [ I18n.t('csv_export.extended.title', username: archive_user.username, site_name: SiteSetting.title) ]
  end

  def extended_note
    [ I18n.t('csv_export.extended.note', username: archive_user.username, site_contact: SiteSetting.contact_email) ]
  end

  def separator(name)
    [["\n"], ["\n"], [name]]
  end

  def user_archive_export_extended(block)
    block.call extended_note

    separator('Posts').each { |l| block.call l }
    block.call Jobs::ExportCsvFile::HEADER_ATTRS_FOR['user_archive']
    user_posts.each { |posts| block.call get_user_archive_fields(posts) }

    separator('Account').each { |l| block.call l }
    block.call ACCOUNT + PROFILE + EMAIL
    block.call user_account

    if user_external_accounts_fields.any?
      separator('External Accounts').each { |l| block.call l }
      block.call user_external_accounts_labels.values
      block.call user_external_accounts
    end

    separator('Statistics').each { |l| block.call l }
    block.call STATS
    block.call user_stats

    separator('Login').each { |l| block.call l }
    block.call AUTH_TOKEN
    block.call user_auth_tokens

    separator('Login History').each { |l| block.call l }
    block.call AUTH_TOKEN_LOGS
    block.call user_auth_token_logs

    separator('Searches').each { |l| block.call l }
    block.call SEARCHES
    user_searches.each { |l| block.call l }

    separator('Topic Views').each { |l| block.call l }
    block.call TOPIC_VIEWS
    user_topic_views.each { |l| block.call l }

    separator('Topic Link Clicks').each { |l| block.call l }
    block.call TOPIC_LINK_CLICKS
    user_topic_link_clicks.each { |l| block.call l }

    separator('Profile Views').each { |l| block.call l }
    block.call PROFILE_VIEWS
    user_profile_views.each { |l| block.call l }

    separator('Actions').each { |l| block.call l }
    block.call ACTIONS
    user_actions.each { |l| block.call l }

    separator('History').each { |l| block.call l }
    block.call HISTORY
    user_history.each { |l| block.call l }
  end

  def user_posts
    Post.includes(topic: :category)
      .where(user_id: archive_user.id)
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
    User.where(id: archive_user.id)
      .joins(:user_profile, :user_emails)
      .select(user_account_fields)
      .first.attributes.values
  end

  def user_external_accounts_fields
    @user_external_accounts_fields ||= begin
      fields = []
      fields.concat GOOGLE.map { |f| "google_user_infos.#{f}" } if GoogleUserInfo.exists?(user_id: archive_user.id)
      fields.concat FACEBOOK.map { |f| "facebook_user_infos.#{f}" } if FacebookUserInfo.exists?(user_id: archive_user.id)
      fields.concat TWITTER.map { |f| "twitter_user_infos.#{f}" } if TwitterUserInfo.exists?(user_id: archive_user.id)
      fields.concat GITHUB.map { |f| "github_user_infos.#{f}" } if GithubUserInfo.exists?(user_id: archive_user.id)
      fields.concat INSTAGRAM.map { |f| "instagram_user_infos.#{f}" } if InstagramUserInfo.exists?(user_id: archive_user.id)
      fields.concat OAUTH.map { |f| "oauth2_user_infos.#{f}" } if Oauth2UserInfo.exists?(user_id: archive_user.id)
      fields.concat OPEN_ID.map { |f| "user_open_ids.#{f}" } if UserOpenId.exists?(user_id: archive_user.id)
      fields.concat SSO.map { |f| "single_sign_on_records.#{f}" } if SingleSignOnRecord.exists?(user_id: archive_user.id)
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
    attributes = User.where(id: archive_user.id)
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
    UserStat.where(user_id: archive_user.id)
      .select(STATS)
      .first.attributes.except("user_id").values
  end

  def user_auth_tokens
    tokens = UserAuthToken.where(user_id: archive_user.id)
      .select(AUTH_TOKEN)
      .first

    tokens ? tokens.attributes.except("id").values : []
  end

  def user_auth_token_logs
    logs = UserAuthTokenLog.where(user_id: archive_user.id)
      .select(AUTH_TOKEN_LOGS)
      .first

    logs ? logs.attributes.except("id").values : []
  end

  def user_actions
    UserAction.where(user_id: archive_user.id)
      .select(ACTIONS)
      .map do |action|
        ACTIONS.map do |k|
          if k === 'action_type'
            ACTION_LABELS[action.attributes[k].to_i]
          else
            action.attributes[k]
          end
        end
      end
  end

  def user_history
    entries = UserHistory.where(acting_user_id: archive_user.id)
      .select(HISTORY)

    if entries.any?
      entries.map do |entry|
        entry.attributes.except("id").map do |k, v|
          if k === "action"
            UserHistory.actions.key(v)
          else
            v
          end
        end
      end
    else
      []
    end
  end

  def user_searches
    SearchLog.where(user_id: archive_user.id)
      .select(SEARCHES)
      .map do |search|
        SEARCHES.map { |k| search.attributes[k] }
      end
  end

  def user_topic_views
    TopicViewItem.where(user_id: archive_user.id)
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
    TopicLinkClick.where(user_id: archive_user.id)
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
    UserProfileView.where(user_id: archive_user.id)
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
