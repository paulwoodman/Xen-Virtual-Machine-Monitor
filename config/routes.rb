ActionController::Routing::Routes.draw do |map|
  map.resource :session

  map.resources :groups

  map.resources :templates

  map.resources :machines

  map.resources :xen_logs

  map.resources :hosts

  map.resources :alerts

  map.resources :users

#  map.root :controller => "login", :action => "index"
  map.root :controller => 'sessions', :action => 'frameset'

  #Login pages
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil
  map.login '/userlogin', :controller => 'sessions', :action => 'new'
  map.login '/userlogin/:success', :controller => 'sessions', :action => 'new'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.change_password '/change_password/:pwusername', :controller => 'users', :action => 'change_password'
  
  #Machine viewer pages
  map.connect 'monitor/alerts', :controller => "monitor", :action => "alerts"
  map.connect 'monitor/available', :controller => "monitor", :action => "available"
  map.connect 'monitor/progressbar', :controller => "monitor", :action => "progressbar"
  map.connect 'monitor/progressbarbuilding', :controller => "monitor", :action => "progressbarbuilding"
  map.connect 'monitor/progressbarstarting', :controller => "monitor", :action => "progressbarstarting"
  map.connect 'monitor/progressbarcommit', :controller => "monitor", :action => "progressbarcommit"
  map.connect 'monitor/machines', :controller => "monitor", :action => "machines"
  map.connect 'monitor/focus', :controller => "monitor", :action => "focus"
  map.connect 'monitor/unfocus', :controller => "monitor", :action => "unfocus"
  map.connect 'monitor/yourvms', :controller => "monitor", :action => "yourvms"
  map.connect 'monitor/popup/:groupname', :controller => "monitor", :action => "popup"
  map.connect 'monitor/start/:groupname', :controller => "monitor", :action => "start"
  map.connect 'monitor/:machinename', :controller => "monitor", :action => "index"

  #Java viewer pages
  map.connect 'viewer/:machinename/:server/:port', :controller => "viewer", :action => "index"

  #Admin pages
  map.connect 'admin/index', :controller => "admin", :action => "index"
  map.connect 'admin/master', :controller => "admin", :action => "master"
  map.connect 'admin/masterlock/:lock', :controller => "admin", :action => "index"
  map.connect 'admin/details', :controller => "admin", :action => "details"
  map.connect 'admin/details/1', :controller => "admin", :action => "details"
  map.connect 'admin/grouplist', :controller => "admin", :action => "grouplist"
  map.connect 'admin/groupremove', :controller => "admin", :action => "groupremove"
  map.connect 'admin/newgroup', :controller => "admin", :action => "index"
  map.connect 'admin/deletegroup/:dgroup', :controller => "admin", :action => "groupremove"
  map.connect 'admin/delete/:dgroup', :controller => "admin", :action => "deletegroup"
  map.connect 'admin/disablegroup/:dgroupname', :controller => "admin", :action => "index"
  map.connect 'admin/enablegroup/:egroupname', :controller => "admin", :action => "index"
  map.connect 'admin/unlockgroup/:ugroupname', :controller => "admin", :action => "index"
  map.connect 'admin/lockgroup/:lgroupname', :controller => "admin", :action => "index"
  map.connect 'admin/setdetails/:sgroupname', :controller => "admin", :action => "index"
  map.connect 'admin/cleardetails/:cdetails', :controller => "admin", :action => "index"
  map.connect 'admin/hosts', :controller => "admin", :action => "hosts"
  map.connect 'admin/alerts', :controller => "admin", :action => "alerts"
  map.connect 'admin/newalert', :controller => "admin", :action => "index"
  map.connect 'admin/deletealert/:delalert', :controller => "admin", :action => "index"
  map.connect 'admin/poweron/:templatename', :controller => "admin", :action => "poweron"
  map.connect 'admin/commit/:templatename', :controller => "admin", :action => "commit"
  map.connect 'admin/start/:templatename', :controller => "admin", :action => "start"
  map.connect 'admin/copy/:templatename', :controller => "admin", :action => "copy"
  map.connect 'admin', :controller => "admin", :action => "index"

  # Log page
  map.connect 'events', :controller => "logs", :action => "index"

  # Useradmin pages
  map.connect 'userinfo', :controller => "userinfo", :action => "index"
  map.connect 'userinfo/adduser', :controller => "userinfo", :action => "adduser"
  map.connect 'userinfo/modify/:username/:attribute', :controller => "userinfo", :action => "index"
  map.connect 'userinfo/delete/:username', :controller => "userinfo", :action => "delete"
  map.connect 'userinfo/execdelete/:username', :controller => "userinfo", :action => "execdelete"
  map.connect 'userinfo/:username', :controller => "userinfo", :action => "index"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
