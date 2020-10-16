class FriendshipsController < ApplicationController

  def create
    begin
      friend = User.find_by_id(params[:friend_id])
      current_user.befriend(friend)
      flash[:notice] = "Added friend."
      redirect_to root_url
    rescue StandardError => e
      flash[:notice] = "#{e}"
      redirect_to root_url
    end
  end
end
