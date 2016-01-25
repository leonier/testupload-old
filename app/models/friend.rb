class Friend < ActiveRecord::Base
  belongs_to :source,  :class_name => "User"
  belongs_to :target,  :class_name => "User"
  # attr_accessible :title, :body
  validates :target_id, uniqueness:  { scope: :source_id }
end
