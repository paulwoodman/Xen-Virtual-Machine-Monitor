class LoginController < ApplicationController
  helper_method :redirect_to
  protect_from_forgery :only => [:create, :update, :destroy]

  def submit
   @getuser=User.find(:all, :select => 'id, username, password', :conditions => ["username = ?", params[:username]])
  end

end
