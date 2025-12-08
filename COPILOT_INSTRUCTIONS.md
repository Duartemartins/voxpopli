# Forum - Rails 8 Twitter Alternative for Builders

A privacy and builder-first microblogging platform. Uses Rails 8 stock stack with SQLite, UUIDs throughout, username-based URLs, invite-only registration, email confirmation, predefined themes, and a builder-friendly API.

---

## Step 1: Create Rails 8 Application with UUID Configuration

Create the application:

```bash
rails new forum --database=sqlite3 --css=tailwind
cd forum
```

In `config/application.rb`, add inside the `Application` class:
```ruby
config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

Create `config/initializers/generators.rb`:
```ruby
Rails.application.config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

Configure `config/database.yml` for production with separate SQLite files:
```yaml
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  queue:
    <<: *default
    database: storage/queue.sqlite3
    migrations_paths: db/queue_migrate
  cache:
    <<: *default
    database: storage/cache.sqlite3
    migrations_paths: db/cache_migrate
  cable:
    <<: *default
    database: storage/cable.sqlite3
    migrations_paths: db/cable_migrate
```

Add to `config/environments/production.rb`:
```ruby
config.solid_queue.connects_to = { database: { writing: :queue } }
config.cache_store = :solid_cache_store
config.active_job.queue_adapter = :solid_queue
```

---

## Step 2: Install and Configure Dependencies

Add to `Gemfile`:
```ruby
gem 'devise'
gem 'rack-attack'
gem 'kaminari'  # pagination
```

Run:
```bash
bundle install
rails generate devise:install
```

Configure Devise in `config/initializers/devise.rb`:
```ruby
Devise.setup do |config|
  config.mailer_sender = 'noreply@yourdomain.com'
  config.paranoid = true  # Don't reveal if email exists
  config.navigational_formats = ['*/*', :html, :turbo_stream]
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
```

Configure Proton Mail SMTP in `config/environments/production.rb`:
```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: "smtp.protonmail.ch",
  port: 587,
  domain: "yourdomain.com",
  user_name: Rails.application.credentials.dig(:proton, :username),
  password: Rails.application.credentials.dig(:proton, :smtp_token),
  authentication: :plain,
  enable_starttls_auto: true
}
config.action_mailer.default_url_options = { host: 'yourdomain.com' }
```

---

## Step 3: Create Database Migrations

Generate and create all migrations with UUIDs:

**Users table** (`rails generate devise User`), then modify migration:
```ruby
class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :username, null: false
      t.string :display_name
      t.text :bio
      t.string :website
      t.string :avatar_url
      t.boolean :is_private, default: false
      t.integer :posts_count, default: 0
      t.integer :followers_count, default: 0
      t.integer :following_count, default: 0
      
      # Confirmable
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email
      
      # Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      
      # Rememberable
      t.datetime :remember_created_at

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
```

**Invites table**:
```ruby
class CreateInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :invites, id: :uuid do |t|
      t.references :inviter, type: :uuid, foreign_key: { to_table: :users }, null: true
      t.references :invitee, type: :uuid, foreign_key: { to_table: :users }, null: true
      t.string :code, null: false
      t.string :email
      t.datetime :used_at
      t.datetime :expires_at
      t.timestamps
    end
    
    add_index :invites, :code, unique: true
  end
end
```

**Themes table**:
```ruby
class CreateThemes < ActiveRecord::Migration[8.0]
  def change
    create_table :themes, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :color, default: '#6366f1'
      t.integer :posts_count, default: 0
      t.timestamps
    end
    
    add_index :themes, :slug, unique: true
  end
end
```

**Posts table**:
```ruby
class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :theme, type: :uuid, foreign_key: true, null: true
      t.references :parent, type: :uuid, foreign_key: { to_table: :posts }, null: true
      t.references :repost_of, type: :uuid, foreign_key: { to_table: :posts }, null: true
      
      t.text :content, null: false
      t.integer :votes_count, default: 0
      t.integer :score, default: 0  # upvotes - downvotes
      t.integer :replies_count, default: 0
      t.integer :reposts_count, default: 0
      
      t.timestamps
    end
    
    add_index :posts, [:user_id, :created_at]
    add_index :posts, :created_at
    add_index :posts, [:score, :created_at]
    add_index :posts, [:theme_id, :created_at]
  end
end
```

**Votes table** (with upvote/downvote support):
```ruby
class CreateVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :votes, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :post, type: :uuid, null: false, foreign_key: true
      t.integer :value, null: false, default: 1  # 1 = upvote, -1 = downvote
      t.timestamps
    end
    
    add_index :votes, [:user_id, :post_id], unique: true
  end
end
```

**Follows table**:
```ruby
class CreateFollows < ActiveRecord::Migration[8.0]
  def change
    create_table :follows, id: :uuid do |t|
      t.references :follower, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :followed, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    
    add_index :follows, [:follower_id, :followed_id], unique: true
  end
end
```

**Bookmarks table**:
```ruby
class CreateBookmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :bookmarks, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :post, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
    
    add_index :bookmarks, [:user_id, :post_id], unique: true
  end
end
```

**Notifications table**:
```ruby
class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :actor, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.string :notifiable_type
      t.uuid :notifiable_id
      t.string :action, null: false
      t.boolean :read, default: false
      t.timestamps
    end
    
    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, [:user_id, :read, :created_at]
  end
end
```

**API Keys table**:
```ruby
class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.string :key_digest, null: false
      t.string :key_prefix, null: false
      t.integer :requests_count, default: 0
      t.integer :rate_limit, default: 1000
      t.datetime :last_used_at
      t.datetime :expires_at
      t.timestamps
    end
    
    add_index :api_keys, :key_prefix, unique: true
  end
end
```

**Webhooks table**:
```ruby
class CreateWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :url, null: false
      t.text :secret
      t.text :events, default: '[]'
      t.boolean :active, default: true
      t.datetime :last_triggered_at
      t.integer :last_status
      t.timestamps
    end
  end
end
```

Run migrations:
```bash
rails db:migrate
```

---

## Step 4: Create Models

**app/models/user.rb**:
```ruby
class User < ApplicationRecord
  RESERVED_USERNAMES = %w[admin api www app mail ftp ssh root user users
                          account accounts settings profile profiles
                          login logout signup register auth oauth
                          help support contact about terms privacy].freeze

  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :confirmable

  has_many :posts, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_posts, through: :bookmarks, source: :post
  has_many :notifications, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :webhooks, dependent: :destroy
  has_one :invite_used, class_name: 'Invite', foreign_key: :invitee_id
  has_many :invites_sent, class_name: 'Invite', foreign_key: :inviter_id

  has_many :active_follows, class_name: 'Follow', foreign_key: :follower_id, dependent: :destroy
  has_many :passive_follows, class_name: 'Follow', foreign_key: :followed_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  validates :username, presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-z0-9_]+\z/, message: "only lowercase letters, numbers, underscores" },
            length: { minimum: 3, maximum: 20 },
            exclusion: { in: RESERVED_USERNAMES, message: "is reserved" }

  normalizes :username, with: -> (u) { u.strip.downcase }
  normalizes :email, with: -> (e) { e.strip.downcase }

  def to_param
    username
  end

  def follow(user)
    return if self == user || following?(user)
    following << user
  end

  def unfollow(user)
    following.delete(user)
  end

  def following?(user)
    following.include?(user)
  end

  def timeline
    Post.where(user_id: following.select(:id))
        .or(Post.where(user_id: id))
        .where(parent_id: nil)
        .includes(:user, :theme)
  end
end
```

**app/models/invite.rb**:
```ruby
class Invite < ApplicationRecord
  belongs_to :inviter, class_name: 'User', optional: true
  belongs_to :invitee, class_name: 'User', optional: true

  validates :code, presence: true, uniqueness: true
  validate :not_expired, on: :use

  before_validation :generate_code, on: :create

  scope :available, -> { where(used_at: nil).where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def available?
    used_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end

  def use!(user)
    raise 'Invite already used' unless available?
    update!(invitee: user, used_at: Time.current)
  end

  private

  def generate_code
    self.code ||= SecureRandom.alphanumeric(12).upcase
  end

  def not_expired
    errors.add(:base, 'Invite has expired') if expires_at.present? && expires_at <= Time.current
    errors.add(:base, 'Invite has already been used') if used_at.present?
  end
end
```

**app/models/theme.rb**:
```ruby
class Theme < ApplicationRecord
  has_many :posts, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug ||= name.parameterize
  end
end
```

**app/models/post.rb**:
```ruby
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :theme, counter_cache: true, optional: true
  belongs_to :parent, class_name: 'Post', optional: true, counter_cache: :replies_count
  belongs_to :repost_of, class_name: 'Post', optional: true, counter_cache: :reposts_count

  has_many :replies, class_name: 'Post', foreign_key: :parent_id, dependent: :destroy
  has_many :reposts, class_name: 'Post', foreign_key: :repost_of_id, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :voters, through: :votes, source: :user
  has_many :bookmarks, dependent: :destroy

  validates :content, presence: true, length: { maximum: 280 }

  scope :by_new, -> { order(created_at: :desc) }
  scope :by_voted, -> { order(score: :desc, created_at: :desc) }
  scope :original, -> { where(parent_id: nil, repost_of_id: nil) }
  scope :for_theme, ->(theme) { where(theme: theme) if theme.present? }

  after_create_commit :notify_mentions
  after_create_commit :trigger_webhooks

  def reply?
    parent_id.present?
  end

  def repost?
    repost_of_id.present?
  end

  def voted_by?(user)
    return false unless user
    votes.exists?(user: user)
  end

  def vote_value_by(user)
    return 0 unless user
    votes.find_by(user: user)&.value || 0
  end

  def recalculate_score!
    update_column(:score, votes.sum(:value))
  end

  private

  def notify_mentions
    mentioned_usernames = content.scan(/@([a-z0-9_]+)/i).flatten.uniq
    User.where(username: mentioned_usernames).find_each do |mentioned_user|
      next if mentioned_user == user
      Notification.create!(
        user: mentioned_user,
        actor: user,
        notifiable: self,
        action: 'mentioned'
      )
    end
  end

  def trigger_webhooks
    user.webhooks.active.each do |webhook|
      events = JSON.parse(webhook.events) rescue []
      if events.include?('post.created')
        WebhookDeliveryJob.perform_later(webhook.id, 'post.created', as_json)
      end
    end
  end
end
```

**app/models/vote.rb** (with upvote/downvote):
```ruby
class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :value, inclusion: { in: [-1, 1] }
  validates :user_id, uniqueness: { scope: :post_id, message: "has already voted on this post" }
  validate :cannot_vote_own_post
  validate :voting_rate_limit

  after_save :update_post_score
  after_destroy :update_post_score
  after_create_commit :create_notification
  after_create_commit :trigger_webhooks

  scope :upvotes, -> { where(value: 1) }
  scope :downvotes, -> { where(value: -1) }

  def upvote?
    value == 1
  end

  def downvote?
    value == -1
  end

  private

  def cannot_vote_own_post
    errors.add(:base, "You cannot vote on your own post") if post&.user_id == user_id
  end

  def voting_rate_limit
    recent_votes = user.votes.where('created_at > ?', 1.minute.ago).count
    errors.add(:base, "You're voting too fast") if recent_votes >= 30
  end

  def update_post_score
    post.recalculate_score!
    post.update_column(:votes_count, post.votes.count)
  end

  def create_notification
    return if post.user == user
    return if downvote?  # Don't notify on downvotes
    Notification.create!(
      user: post.user,
      actor: user,
      notifiable: post,
      action: 'voted'
    )
  end

  def trigger_webhooks
    post.user.webhooks.active.each do |webhook|
      events = JSON.parse(webhook.events) rescue []
      if events.include?('post.voted')
        WebhookDeliveryJob.perform_later(webhook.id, 'post.voted', { 
          post_id: post_id, 
          voter_id: user_id,
          value: value,
          new_score: post.score
        })
      end
    end
  end
end
```

**app/models/follow.rb**:
```ruby
class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User', counter_cache: :following_count
  belongs_to :followed, class_name: 'User', counter_cache: :followers_count

  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :cannot_follow_self

  after_create_commit :create_notification

  private

  def cannot_follow_self
    errors.add(:base, "You cannot follow yourself") if follower_id == followed_id
  end

  def create_notification
    Notification.create!(
      user: followed,
      actor: follower,
      notifiable: self,
      action: 'followed'
    )
  end
end
```

**app/models/bookmark.rb**:
```ruby
class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :user_id, uniqueness: { scope: :post_id }
end
```

**app/models/notification.rb**:
```ruby
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: 'User'
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(50) }

  def mark_as_read!
    update!(read: true)
  end
end
```

**app/models/api_key.rb**:
```ruby
class ApiKey < ApplicationRecord
  belongs_to :user

  validates :name, presence: true

  before_create :generate_key

  attr_accessor :raw_key

  def self.authenticate(token)
    return nil unless token.present?
    prefix = token[0..15]
    api_key = find_by(key_prefix: prefix)
    return nil unless api_key
    BCrypt::Password.new(api_key.key_digest) == token ? api_key : nil
  end

  def increment_usage!
    increment!(:requests_count)
    touch(:last_used_at)
  end

  def rate_limit_exceeded?
    requests_count >= rate_limit
  end

  private

  def generate_key
    self.raw_key = "bb_live_#{SecureRandom.hex(24)}"
    self.key_prefix = raw_key[0..15]
    self.key_digest = BCrypt::Password.create(raw_key)
  end
end
```

**app/models/webhook.rb**:
```ruby
class Webhook < ApplicationRecord
  belongs_to :user

  EVENTS = %w[post.created post.voted user.followed].freeze

  encrypts :secret

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[https]) }
  validate :validate_events

  before_create :generate_secret

  scope :active, -> { where(active: true) }

  def events_list
    JSON.parse(events) rescue []
  end

  def events_list=(arr)
    self.events = arr.to_json
  end

  private

  def generate_secret
    self.secret = SecureRandom.hex(32)
  end

  def validate_events
    parsed = JSON.parse(events) rescue []
    errors.add(:events, 'must be present') if parsed.empty?
    invalid = parsed - EVENTS
    errors.add(:events, "contains invalid events: #{invalid.join(', ')}") if invalid.any?
  end
end
```

---

## Step 5: Create Controllers

**app/controllers/application_controller.rb**:
```ruby
class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :invite_code])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :display_name, :bio, :website])
  end
end
```

**app/controllers/registrations_controller.rb** (custom Devise):
```ruby
class RegistrationsController < Devise::RegistrationsController
  before_action :validate_invite_code, only: [:new, :create]

  def new
    @invite = Invite.available.find_by!(code: params[:invite_code])
    super
  end

  def create
    @invite = Invite.available.find_by!(code: params[:user][:invite_code])
    super do |user|
      if user.persisted?
        @invite.use!(user)
      end
    end
  end

  def destroy
    current_user.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroyed
    yield if block_given?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  private

  def validate_invite_code
    code = params[:invite_code] || params.dig(:user, :invite_code)
    unless code.present? && Invite.available.exists?(code: code)
      redirect_to root_path, alert: 'Valid invite code required to register'
    end
  end
end
```

**app/controllers/timeline_controller.rb**:
```ruby
class TimelineController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    @view = params[:view].presence_in(%w[new voted]) || 'new'
    @theme = Theme.find_by(slug: params[:theme]) if params[:theme].present?

    base_posts = if user_signed_in?
      current_user.timeline
    else
      Post.original
    end

    base_posts = base_posts.for_theme(@theme)

    @posts = case @view
    when 'new'
      base_posts.by_new
    when 'voted'
      base_posts.by_voted
    end.includes(:user, :theme).page(params[:page]).per(25)
  end
end
```

**app/controllers/posts_controller.rb**:
```ruby
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_post, only: [:show, :destroy]

  def show
    @replies = @post.replies.includes(:user).by_new
  end

  def create
    @post = current_user.posts.build(post_params)

    respond_to do |format|
      if @post.save
        format.turbo_stream
        format.html { redirect_to timeline_path, notice: 'Post created' }
      else
        format.html { redirect_to timeline_path, alert: @post.errors.full_messages.join(', ') }
      end
    end
  end

  def destroy
    if @post.user == current_user
      @post.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@post) }
        format.html { redirect_to timeline_path, notice: 'Post deleted' }
      end
    else
      redirect_to timeline_path, alert: 'Not authorized'
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:content, :theme_id, :parent_id)
  end
end
```

**app/controllers/votes_controller.rb** (with upvote/downvote):
```ruby
class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    value = params[:value].to_i
    value = 1 unless value.in?([-1, 1])
    
    @vote = @post.votes.find_by(user: current_user)

    respond_to do |format|
      if @vote
        # Change vote or remove if same value
        if @vote.value == value
          @vote.destroy
          @vote = nil
        else
          @vote.update(value: value)
        end
      else
        @vote = @post.votes.create(user: current_user, value: value)
      end

      @post.reload
      format.turbo_stream
      format.html { redirect_back fallback_location: timeline_path }
    end
  end

  def destroy
    @vote = @post.votes.find_by(user: current_user)
    @vote&.destroy
    @post.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: timeline_path }
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
```

**app/controllers/users_controller.rb**:
```ruby
class UsersController < ApplicationController
  before_action :set_user

  def show
    @posts = @user.posts.original.by_new.includes(:theme).page(params[:page]).per(25)
  end

  private

  def set_user
    @user = User.find_by!(username: params[:username])
  end
end
```

**app/controllers/follows_controller.rb**:
```ruby
class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    current_user.follow(@user)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: user_path(@user) }
    end
  end

  def destroy
    current_user.unfollow(@user)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: user_path(@user) }
    end
  end

  private

  def set_user
    @user = User.find_by!(username: params[:user_username])
  end
end
```

**app/controllers/settings/accounts_controller.rb**:
```ruby
module Settings
  class AccountsController < ApplicationController
    before_action :authenticate_user!

    def show
    end

    def destroy
      current_user.destroy
      sign_out current_user
      redirect_to root_path, notice: 'Your account has been permanently deleted'
    end
  end
end
```

---

## Step 6: Create API Controllers

**app/controllers/api/v1/base_controller.rb**:
```ruby
module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_key!

      private

      def authenticate_api_key!
        token = request.headers['Authorization']&.split(' ')&.last
        @api_key = ApiKey.authenticate(token)

        unless @api_key
          render json: { error: 'Invalid or missing API key' }, status: :unauthorized
        end
      end

      def current_user
        @api_key&.user
      end

      def check_rate_limit!
        if @api_key.rate_limit_exceeded?
          render json: { error: 'Rate limit exceeded', retry_after: 1.hour.to_i }, status: :too_many_requests
        else
          @api_key.increment_usage!
        end
      end
    end
  end
end
```

**app/controllers/api/v1/posts_controller.rb**:
```ruby
module Api
  module V1
    class PostsController < BaseController
      before_action :check_rate_limit!

      def index
        sort = params[:sort].presence_in(%w[new voted]) || 'new'
        theme = Theme.find_by(slug: params[:theme])

        posts = Post.original.for_theme(theme)
        posts = sort == 'voted' ? posts.by_voted : posts.by_new
        posts = posts.includes(:user, :theme).page(params[:page]).per(25)

        render json: {
          data: posts.map { |p| serialize_post(p) },
          meta: { page: posts.current_page, total_pages: posts.total_pages }
        }
      end

      def show
        post = Post.find(params[:id])
        render json: { data: serialize_post(post) }
      end

      def create
        post = current_user.posts.build(post_params)

        if post.save
          render json: { data: serialize_post(post) }, status: :created
        else
          render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        post = current_user.posts.find(params[:id])
        post.destroy
        head :no_content
      end

      private

      def post_params
        params.permit(:content, :theme_id, :parent_id)
      end

      def serialize_post(post)
        {
          id: post.id,
          content: post.content,
          score: post.score,
          votes_count: post.votes_count,
          replies_count: post.replies_count,
          theme: post.theme&.slug,
          user: { id: post.user.id, username: post.user.username },
          created_at: post.created_at.iso8601
        }
      end
    end
  end
end
```

**app/controllers/api/v1/votes_controller.rb** (with upvote/downvote):
```ruby
module Api
  module V1
    class VotesController < BaseController
      before_action :check_rate_limit!

      def create
        post = Post.find(params[:post_id])
        value = params[:value].to_i
        value = 1 unless value.in?([-1, 1])

        vote = post.votes.find_by(user: current_user)

        if vote
          if vote.value == value
            vote.destroy
            render json: { data: { post_id: post.id, score: post.reload.score, voted: nil } }
          else
            vote.update!(value: value)
            render json: { data: { post_id: post.id, score: post.reload.score, voted: value } }
          end
        else
          vote = post.votes.create!(user: current_user, value: value)
          render json: { data: { post_id: post.id, score: post.reload.score, voted: value } }, status: :created
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def destroy
        post = Post.find(params[:post_id])
        vote = post.votes.find_by!(user: current_user)
        vote.destroy
        render json: { data: { post_id: post.id, score: post.reload.score, voted: nil } }
      end
    end
  end
end
```

**app/controllers/api/v1/themes_controller.rb**:
```ruby
module Api
  module V1
    class ThemesController < BaseController
      skip_before_action :authenticate_api_key!, only: [:index, :show]

      def index
        themes = Theme.all.order(:name)
        render json: {
          data: themes.map { |t| serialize_theme(t) }
        }
      end

      def show
        theme = Theme.find_by!(slug: params[:id])
        render json: { data: serialize_theme(theme) }
      end

      private

      def serialize_theme(theme)
        {
          id: theme.id,
          name: theme.name,
          slug: theme.slug,
          description: theme.description,
          color: theme.color,
          posts_count: theme.posts_count
        }
      end
    end
  end
end
```

**app/controllers/api/v1/me_controller.rb**:
```ruby
module Api
  module V1
    class MeController < BaseController
      def show
        render json: {
          data: {
            id: current_user.id,
            username: current_user.username,
            email: current_user.email,
            display_name: current_user.display_name,
            bio: current_user.bio,
            posts_count: current_user.posts_count,
            followers_count: current_user.followers_count,
            following_count: current_user.following_count
          }
        }
      end
    end
  end
end
```

---

## Step 7: Configure Routes

**config/routes.rb**:
```ruby
Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'registrations' }

  root 'timeline#index'
  get 'timeline', to: 'timeline#index'

  resources :posts, only: [:show, :create, :destroy] do
    resource :vote, only: [:create, :destroy]
  end

  resources :users, param: :username, only: [:show] do
    resource :follow, only: [:create, :destroy]
  end

  namespace :settings do
    resource :account, only: [:show, :destroy]
  end

  namespace :api do
    namespace :v1 do
      resources :posts, only: [:index, :show, :create, :destroy] do
        resource :vote, only: [:create, :destroy]
      end
      resources :themes, only: [:index, :show]
      resource :me, only: [:show], controller: 'me'
    end
  end

  get 'up', to: 'rails/health#show', as: :rails_health_check
end
```

---

## Step 8: Configure Rack Attack

**config/initializers/rack_attack.rb**:
```ruby
class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Safelist localhost
  safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end

  # API rate limit by IP
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Login throttle
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == '/users/sign_in' && req.post?
  end

  # Registration throttle
  throttle('registrations/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path == '/users' && req.post?
  end

  # Block bad actors
  blocklist('block-bad-requests') do |req|
    Rack::Attack::Fail2Ban.filter("badreq-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      req.path.include?('.php') || req.path.include?('wp-admin')
    end
  end

  self.throttled_responder = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [429, { 'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s },
     [{ error: 'Rate limit exceeded', retry_after: retry_after }.to_json]]
  end
end
```

In **config/application.rb**, add:
```ruby
config.middleware.use Rack::Attack
```

---

## Step 9: Create Background Jobs

**app/jobs/webhook_delivery_job.rb**:
```ruby
class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks
  retry_on Net::OpenTimeout, wait: :exponentially_longer, attempts: 5

  def perform(webhook_id, event, payload)
    webhook = Webhook.find(webhook_id)
    return unless webhook.active?

    signature = OpenSSL::HMAC.hexdigest('sha256', webhook.secret, payload.to_json)

    uri = URI(webhook.url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['X-Webhook-Signature'] = "sha256=#{signature}"
    request['X-Webhook-Event'] = event
    request.body = payload.to_json

    response = http.request(request)

    webhook.update!(last_triggered_at: Time.current, last_status: response.code.to_i)
  end
end
```

---

## Step 10: Seed Initial Data

**db/seeds.rb**:
```ruby
# Create initial theme
Theme.find_or_create_by!(slug: 'build-in-public') do |t|
  t.name = 'Build in Public'
  t.description = 'Share your building journey with the community'
  t.color = '#6366f1'
end

# Create initial admin invites
10.times do
  Invite.create!(expires_at: 1.month.from_now)
end

puts "Created theme: Build in Public"
puts "Created 10 invite codes:"
Invite.all.each { |i| puts "  #{i.code}" }
```

Run:
```bash
rails db:seed
```

---

## Step 11: Configure Kamal Deployment

**config/deploy.yml**:
```yaml
service: forum
image: yourregistry/forum

servers:
  web:
    - your.server.ip

registry:
  username: registry-user
  password:
    - KAMAL_REGISTRY_PASSWORD

builder:
  arch: amd64

env:
  clear:
    RAILS_ENV: production
    SOLID_QUEUE_IN_PUMA: true
  secret:
    - RAILS_MASTER_KEY
    - SECRET_KEY_BASE

volumes:
  - "forum_storage:/rails/storage"

healthcheck:
  path: /up
  port: 3000
  max_attempts: 10
  interval: 20s

traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt:/letsencrypt"
```

Deploy:
```bash
kamal setup
kamal deploy
```

---

## Step 12: Security Headers

**config/initializers/content_security_policy.rb**:
```ruby
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self
  policy.img_src     :self, :data
  policy.object_src  :none
  policy.script_src  :self
  policy.style_src   :self, :unsafe_inline
  policy.connect_src :self
  policy.frame_ancestors :none
end

Rails.application.config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
```

**config/application.rb** add:
```ruby
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'DENY',
  'X-Content-Type-Options' => 'nosniff',
  'X-XSS-Protection' => '0',
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  'Permissions-Policy' => 'geolocation=(), microphone=(), camera=()'
}
```

---

## Step 13: Create Turbo Stream Templates for Voting

**app/views/votes/create.turbo_stream.erb**:
```erb
<%= turbo_stream.replace dom_id(@post, :vote) do %>
  <%= render partial: 'posts/vote_buttons', locals: { post: @post } %>
<% end %>
```

**app/views/votes/destroy.turbo_stream.erb**:
```erb
<%= turbo_stream.replace dom_id(@post, :vote) do %>
  <%= render partial: 'posts/vote_buttons', locals: { post: @post } %>
<% end %>
```

**app/views/posts/_vote_buttons.html.erb**:
```erb
<div id="<%= dom_id(post, :vote) %>" class="flex items-center gap-2">
  <% user_vote = current_user ? post.vote_value_by(current_user) : 0 %>
  
  <%= button_to post_vote_path(post, value: 1), method: :post, 
      class: "p-1 rounded #{user_vote == 1 ? 'text-green-500' : 'text-gray-400 hover:text-green-500'}" do %>
    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M3.293 9.707a1 1 0 010-1.414l6-6a1 1 0 011.414 0l6 6a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L4.707 9.707a1 1 0 01-1.414 0z" clip-rule="evenodd"/>
    </svg>
  <% end %>
  
  <span class="font-medium <%= post.score > 0 ? 'text-green-600' : post.score < 0 ? 'text-red-600' : 'text-gray-500' %>">
    <%= post.score %>
  </span>
  
  <%= button_to post_vote_path(post, value: -1), method: :post,
      class: "p-1 rounded #{user_vote == -1 ? 'text-red-500' : 'text-gray-400 hover:text-red-500'}" do %>
    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M16.707 10.293a1 1 0 010 1.414l-6 6a1 1 0 01-1.414 0l-6-6a1 1 0 111.414-1.414L9 14.586V3a1 1 0 012 0v11.586l4.293-4.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
    </svg>
  <% end %>
</div>
```

---

## Step 14: Create Views

**app/views/layouts/application.html.erb**:
```erb
<!DOCTYPE html>
<html>
  <head>
    <title>Forum</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="bg-gray-50 min-h-screen">
    <nav class="bg-white border-b border-gray-200">
      <div class="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between">
        <%= link_to 'Forum', root_path, class: 'text-xl font-bold text-indigo-600' %>
        <div class="flex items-center gap-4">
          <% if user_signed_in? %>
            <%= link_to current_user.username, user_path(current_user), class: 'text-gray-600 hover:text-gray-900' %>
            <%= button_to 'Sign out', destroy_user_session_path, method: :delete, class: 'text-gray-600 hover:text-gray-900' %>
          <% else %>
            <%= link_to 'Sign in', new_user_session_path, class: 'text-gray-600 hover:text-gray-900' %>
          <% end %>
        </div>
      </div>
    </nav>

    <main class="max-w-4xl mx-auto px-4 py-6">
      <% if notice %>
        <div class="mb-4 p-3 bg-green-100 text-green-800 rounded"><%= notice %></div>
      <% end %>
      <% if alert %>
        <div class="mb-4 p-3 bg-red-100 text-red-800 rounded"><%= alert %></div>
      <% end %>
      <%= yield %>
    </main>
  </body>
</html>
```

**app/views/timeline/index.html.erb**:
```erb
<div class="space-y-6">
  <% if user_signed_in? %>
    <%= render 'posts/form' %>
  <% end %>

  <div class="flex gap-4 border-b border-gray-200 pb-2">
    <%= link_to 'New', timeline_path(view: 'new', theme: params[:theme]), 
        class: "pb-2 border-b-2 #{@view == 'new' ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-gray-500 hover:text-gray-700'}" %>
    <%= link_to 'Top', timeline_path(view: 'voted', theme: params[:theme]),
        class: "pb-2 border-b-2 #{@view == 'voted' ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-gray-500 hover:text-gray-700'}" %>
  </div>

  <div id="posts" class="space-y-4">
    <%= render @posts %>
  </div>

  <div class="mt-6">
    <%= paginate @posts %>
  </div>
</div>
```

**app/views/posts/_form.html.erb**:
```erb
<%= form_with model: Post.new, class: 'bg-white rounded-lg shadow p-4' do |f| %>
  <%= f.text_area :content, 
      placeholder: "What are you building?",
      class: 'w-full border border-gray-300 rounded-lg p-3 focus:ring-2 focus:ring-indigo-500 focus:border-transparent resize-none',
      rows: 3,
      maxlength: 280 %>
  
  <div class="flex items-center justify-between mt-3">
    <%= f.collection_select :theme_id, Theme.all, :id, :name, 
        { include_blank: 'Select theme (optional)' },
        { class: 'border border-gray-300 rounded px-3 py-2' } %>
    
    <%= f.submit 'Post', class: 'bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 cursor-pointer' %>
  </div>
<% end %>
```

**app/views/posts/_post.html.erb**:
```erb
<div id="<%= dom_id(post) %>" class="bg-white rounded-lg shadow p-4">
  <div class="flex gap-4">
    <div class="flex-shrink-0">
      <%= render 'posts/vote_buttons', post: post %>
    </div>
    
    <div class="flex-1 min-w-0">
      <div class="flex items-center gap-2 text-sm text-gray-500">
        <%= link_to post.user.username, user_path(post.user), class: 'font-medium text-gray-900 hover:underline' %>
        <% if post.theme %>
          <span class="px-2 py-0.5 rounded text-xs" style="background-color: <%= post.theme.color %>20; color: <%= post.theme.color %>">
            <%= post.theme.name %>
          </span>
        <% end %>
        <span>·</span>
        <span><%= time_ago_in_words(post.created_at) %> ago</span>
      </div>
      
      <p class="mt-2 text-gray-900"><%= post.content %></p>
      
      <div class="mt-3 flex items-center gap-4 text-sm text-gray-500">
        <%= link_to post_path(post), class: 'hover:text-gray-700' do %>
          <%= post.replies_count %> replies
        <% end %>
        
        <% if user_signed_in? && post.user == current_user %>
          <%= button_to 'Delete', post_path(post), method: :delete, 
              class: 'text-red-500 hover:text-red-700',
              data: { turbo_confirm: 'Are you sure?' } %>
        <% end %>
      </div>
    </div>
  </div>
</div>
```

**app/views/posts/show.html.erb**:
```erb
<div class="space-y-6">
  <%= render @post %>

  <% if user_signed_in? %>
    <%= form_with model: Post.new, class: 'bg-white rounded-lg shadow p-4' do |f| %>
      <%= f.hidden_field :parent_id, value: @post.id %>
      <%= f.text_area :content, 
          placeholder: "Write a reply...",
          class: 'w-full border border-gray-300 rounded-lg p-3 focus:ring-2 focus:ring-indigo-500 focus:border-transparent resize-none',
          rows: 2,
          maxlength: 280 %>
      <div class="flex justify-end mt-3">
        <%= f.submit 'Reply', class: 'bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 cursor-pointer' %>
      </div>
    <% end %>
  <% end %>

  <div class="space-y-4">
    <h3 class="font-medium text-gray-900">Replies</h3>
    <%= render @replies %>
  </div>
</div>
```

**app/views/users/show.html.erb**:
```erb
<div class="space-y-6">
  <div class="bg-white rounded-lg shadow p-6">
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">
          <%= @user.display_name || @user.username %>
        </h1>
        <p class="text-gray-500">@<%= @user.username %></p>
        <% if @user.bio.present? %>
          <p class="mt-2 text-gray-700"><%= @user.bio %></p>
        <% end %>
      </div>
      
      <% if user_signed_in? && current_user != @user %>
        <% if current_user.following?(@user) %>
          <%= button_to 'Unfollow', user_follow_path(@user), method: :delete,
              class: 'px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50' %>
        <% else %>
          <%= button_to 'Follow', user_follow_path(@user), method: :post,
              class: 'px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700' %>
        <% end %>
      <% end %>
    </div>
    
    <div class="mt-4 flex gap-4 text-sm">
      <span><strong><%= @user.posts_count %></strong> posts</span>
      <span><strong><%= @user.followers_count %></strong> followers</span>
      <span><strong><%= @user.following_count %></strong> following</span>
    </div>
  </div>

  <div class="space-y-4">
    <%= render @posts %>
  </div>

  <div class="mt-6">
    <%= paginate @posts %>
  </div>
</div>
```

**app/views/settings/accounts/show.html.erb**:
```erb
<div class="max-w-xl space-y-6">
  <h1 class="text-2xl font-bold">Account Settings</h1>

  <div class="bg-white rounded-lg shadow p-6">
    <h2 class="text-lg font-medium text-red-600">Danger Zone</h2>
    <p class="mt-2 text-gray-600">Once you delete your account, there is no going back. Please be certain.</p>
    
    <%= button_to 'Delete my account', settings_account_path, method: :delete,
        class: 'mt-4 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700',
        data: { turbo_confirm: 'Are you absolutely sure? This cannot be undone.' } %>
  </div>
</div>
```

---

## Summary

This creates a complete Rails 8 application with:
- **UUIDs** as primary keys throughout
- **Username-based URLs** for user profiles (`/users/:username`)
- **Invite-only registration** with required email confirmation
- **Predefined themes** (starting with "Build in Public")
- **Timeline views**: "new" and "most voted" (by score)
- **Upvote/downvote voting** with score calculation, rate limiting, and manipulation prevention
- **Builder-friendly API** with API keys, rate limiting, and webhooks
- **Privacy-first**: No tracking, minimal data, account deletion
- **SQLite + Solid Queue/Cache/Cable** (no Redis needed)
- **Importmaps** (no Node.js required)
- **Kamal deployment** ready
- **Proton Mail** for transactional email
