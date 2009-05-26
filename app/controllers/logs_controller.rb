class LogsController < ApplicationController
  helper_method :redirect_to
  protect_from_forgery :only => [:create, :update, :destroy] 

  def index
    @logshow = XenLog.find(:all, :order => "id DESC")
  end

end
