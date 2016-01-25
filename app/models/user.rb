class User < ActiveRecord::Base
  attr_accessible :name, :password_hash, :salt
  has_many :uptest
  has_many :notification
  has_many :postthread
  has_many :postreply
  has_many :friend, :class_name => 'Friend', :foreign_key => 'source_id'
end
