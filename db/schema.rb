# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090501145840) do

  create_table "alerts", :force => true do |t|
    t.string "message",                :null => false
    t.string "username", :limit => 25, :null => false
  end

  create_table "groups", :force => true do |t|
    t.string  "name",      :limit => 35,                :null => false
    t.string  "tname",     :limit => 35,                :null => false
    t.integer "lock",      :limit => 4,  :default => 0, :null => false
    t.string  "owner",     :limit => 25,                :null => false
    t.integer "available", :limit => 11, :default => 0, :null => false
  end

  create_table "hosts", :force => true do |t|
    t.string  "uuid",     :limit => 36,                 :null => false
    t.text    "ip",       :limit => 255,                :null => false
    t.text    "hostname", :limit => 255,                :null => false
    t.integer "live",     :limit => 4,   :default => 1, :null => false
  end

  create_table "machines", :force => true do |t|
    t.string    "uuid",      :limit => 36
    t.text      "ip",        :limit => 255,                :null => false
    t.string    "name",      :limit => 50,                 :null => false
    t.integer   "hdsize",    :limit => 4
    t.integer   "ram",       :limit => 11
    t.integer   "state",     :limit => 4,   :default => 0, :null => false
    t.string    "hostuuid",  :limit => 36
    t.integer   "vncport",   :limit => 11,  :default => 0, :null => false
    t.timestamp "starttime"
    t.text      "username",  :limit => 255
    t.integer   "used",      :limit => 4,   :default => 1
    t.text      "group",     :limit => 255
    t.integer   "freemem",   :limit => 11
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.integer  "gid",                       :limit => 3
    t.string   "name"
    t.string   "activevm"
    t.string   "activetemplate"
  end

  create_table "xen_logs", :force => true do |t|
    t.integer   "logtype", :limit => 4, :null => false
    t.timestamp "time",                 :null => false
    t.text      "message",              :null => false
  end

end
