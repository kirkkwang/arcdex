module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      user = authenticated_user || guest_user_from_session
      return reject_unauthorized_connection if user.nil?

      user
    end

    def authenticated_user
      env['warden']&.user
    end

    def guest_user_from_session
      User.find_by(email: request.session['guest_user_id'], guest: true)
    end
  end
end
