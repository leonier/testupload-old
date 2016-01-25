require 'digest'
require 'securerandom'
class UserController < ApplicationController
	def loginpage
		if session[:user_id] != nil
			if User.find_by_id(session[:user_id]) != nil
				@error = "Already logon to system!"
				render "error"
				return
			end
		end
		if params[:gotoforum]=="1"
			@gotoforum=1
		end
	end
	def login
		if session[:user_id] != nil
			if User.find_by_id(session[:user_id]) != nil
				@error = "Already logon to system!"
				render "error"
				return
			end
		end
		
		flash[:username]=params[:username]
		
		if checkusername(params[:username], "loginpage") == false
			return
		end
		if checkpassword(params[:password], "loginpage") == false
			return
		end
		testuser=User.where(:name => params[:username]).first
		if testuser.blank?
			flash[:error]="Wrong Username or Password!"
			redirect_to :action=> "loginpage"
			return
		end
		salt=testuser.salt
		hash = genhash(params[:password], salt)
		if hash != testuser.password_hash
			flash[:error]="Wrong Username or Password!"
			redirect_to :action=> "loginpage"
			return		
		end
		session[:user_id]=testuser.id
		if params[:gotoforum]!= '1'
			redirect_to :controller=> "uptest", :action=> "index"
		else
			redirect_to :controller=> "postthread", :action=> "index"
		end
	end
	def logout
		session[:user_id] = nil
		redirect_to :controller=> "uptest", :action=> "index"
	end
	def register
		flash[:username]=params[:username]
		
		if checkusername(params[:username], "registerpage") == false
			return
		end
		if checkpassword(params[:password], "registerpage") == false
			return
		end
		
		salt = SecureRandom.hex
		hash = genhash(params[:password], salt)
		@result= "User:"+params[:username]
		
		newuser=User.new
		newuser.name=params[:username]
		newuser.password_hash=hash
		newuser.salt=salt
		if newuser.save!
			
		else
			flash[:error]="Save error!"
			redirect_to :action=> referer
		end
	end
	def registerpage
	
	end
	def change_password_page
		if session[:user_id] == nil
			@error="Not logged in!"
			render "error"
			return
		end
		@user=User.find_by_id(session[:user_id])
		if @user.blank?
			@error="Not logged in!"
			render "error"
			return
		end	
	end
	def change_password
		if session[:user_id] == nil
			@error="Not logged in!"
			render "error"
			return
		end
		@user=User.find_by_id(session[:user_id])
		if @user.blank?
			@error="Not logged in!"
			render "error"
			return
		end	
		testuser=User.find_by_id(params[:user_id])
		if testuser.blank?
			@error="Wrong user ID!"
			render "error"
			return
		end
		if testuser.id!=@user.id
			@error="Wrong user ID!"
			render "error"
			return		
		end
		if checkpassword2(params[:oldpassword]) == false
			return
		end
		salt=testuser.salt
		hash = genhash(params[:oldpassword], salt)
		if hash != testuser.password_hash
			flash[:error]="Wrong old password!"
			redirect_to :action=> "change_password_page"
			return		
		end
		if params[:newpassword] != params[:newpassword1]
			flash[:error]="New passwords must be entered correctly for 2 times!"
			redirect_to :action=>"change_password_page"
			return		
		end		
		if checkpassword2(params[:newpassword]) == false
			return
		end
		
		salt = SecureRandom.hex
		hash = genhash(params[:newpassword], salt)
		
		testuser.password_hash=hash
		testuser.salt=salt
		testuser.save!
		flash[:error]="Successfully updated password for user "+testuser.name
		redirect_to :controller=> "uptest", :action=> "index"
	end
	def friends
		if session[:user_id] == nil
			@error="Not logged in!"
			render "error"
			return
		end
		@user=User.find_by_id(session[:user_id])
		if @user.blank?
			@error="Not logged in!"
			render "error"
			return
		end	
		@friends=Friend.where(:source_id=>@user.id )
		@allusers=User.all
		@allusers.delete_if{|userx| userx.id==@user.id}
		@friends.each do |friends|
			@allusers.delete_if{|userx| userx.id==friends.target_id}
		end
	end
	def friend_delete
		if session[:user_id] == nil
			@error="Not logged in!"
			render "error"
			return
		end
		@user=User.find_by_id(session[:user_id])
		if @user.blank?
			@error="Not logged in!"
			render "error"
			return
		end	
		friendtodelete=Friend.find_by_id(params[:fid])
		unless friendtodelete.blank?
			friendtodelete.destroy
		end
		redirect_to :back	
	end
	def friend_add
		if session[:user_id] == nil
			@error="Not logged in!"
			render "error"
			return
		end
		@user=User.find_by_id(session[:user_id])
		if @user.blank?
			@error="Not logged in!"
			render "error"
			return
		end	
		newfrienduser=User.find_by_id(params[:target_id])
		unless newfrienduser.blank?
			newfriend=Friend.new
			newfriend.source_id=@user.id
			newfriend.target_id=newfrienduser.id
			newfriend.approved=false
			newfriend.save!
		end
		redirect_to :back
	end
	def friend_approve_list
		if session[:user_id] == nil
			@error="Not logged in!"
			render "error"
			return
		end
		@user=User.find_by_id(session[:user_id])
		if @user.blank?
			@error="Not logged in!"
			render "error"
			return
		end	
		@targetfriend=Friend.where(:target_id=>@user.id, :approved=>false)
	end
	def friend_approve
		unless params[:friend_json].blank?
			hash=JSON.parse(params[:friend_json])
			hash.each do |req|
				friend=Friend.find_by_id(req['fid'])
				if req['approve'] == 1
					friend.approved=true
					friend.save!
				end
				if req['refuse'] == 1
					friend.destroy
				end			
			end
		end
		redirect_to :controller=>"uptest", :action=>"index"
	end
	def batchaddfriend
		unless params[:newfriend_json].blank?
			hash=JSON.parse(params[:newfriend_json])
			hash.each do |friend|
				puts "source:"+friend['source'].to_s
				puts "target:"+friend['target'].to_s
				if friend['source']!=friend['target']
					newfriend=Friend.new
					newfriend.source_id=friend['source']
					newfriend.target_id=friend['target']
					newfriend.approved=true
					newfriend.save!
				end
			end
		end
		unless params[:delfriend_json].blank?
			hash=JSON.parse(params[:delfriend_json])
			hash.each do |friend|
				f=Friend.find_by_id(friend['fid'])
				f.destroy
			end
		end
		redirect_to :back
	end
private
	def checkusername(username, referer)
		if username.empty?
			flash[:error]="Please input your User name!"
			redirect_to :action=> referer
			return false
		end
		if username.length<5 or username.length>25
			flash[:error]="User name length too long or too short!"
			redirect_to :action=> referer
			return false
		end
		if all_letters_or_digits(username) == false
			flash[:error]="User name should only contain letters or digits or -/_!"
			redirect_to :action=> referer
			return false
		end
	end
	def checkpassword(password, referer)
		if password.empty?
			flash[:error]="Please input your Password!"
			redirect_to :action=> referer
			return false
		end
		if password.length<5 or password.length>25
			flash[:error]="Password length too long or too short!"
			redirect_to :action=> referer
			return false
		end	
	end
	def checkpassword2(password)
		if password.empty?
			flash[:error]="Please input your Password!"
			redirect_to :action=>"change_password_page"
			return false
		end
		if password.length<5 or password.length>25
			flash[:error]="Password length too long or too short!"
			redirect_to :action=>"change_password_page"
			return false
		end	
	end
	def genhash(password, salt)
		mypassword=password+salt
		myhash=Digest::SHA1.hexdigest(mypassword)
		return myhash
	end
	def all_letters_or_digits(str)
		str[/[a-zA-Z0-9-_]+/]  == str
	end
end
