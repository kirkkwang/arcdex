class BookmarksChannel < ApplicationCable::Channel
  def subscribed
    stream_from "bookmarks_#{current_user.id}" if current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
