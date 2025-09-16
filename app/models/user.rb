class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  # Configuration added by Blacklight; Blacklight::User uses a method key on your
  # user class to get a user-displayable login/identifier for
  # the account.
  self.string_display_key ||= :email

  serialize :bookmark_order, coder: JSON, default: []

  def ordered_bookmark_ids
    bookmark_order.presence || bookmarks.order(:created_at).pluck(:document_id)
  end

  def update_bookmark_order!(new_order)
    update!(bookmark_order: new_order)
  end

  # Helper to clean up order when bookmarks are deleted
  # def cleanup_bookmark_order!
  #   return unless bookmark_order.present?

  #   current_bookmark_ids = bookmarks.pluck(:document_id)
  #   cleaned_order = bookmark_order & current_bookmark_ids
  #   update!(bookmark_order: cleaned_order) if cleaned_order != bookmark_order
  # end

  def self.from_google(u)
    create_with(uid: u[:uid], provider: 'google', avatar_url: u[:avatar_url],
                password: Devise.friendly_token[0, 20]).find_or_create_by!(email: u[:email])
  end
end
