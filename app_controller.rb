require 'sinatra'
require 'json'

get '/registrations/signup' do
    erb :'/registrations/signup'
end

#instead of the above code that 
#get '/application_controller' do
#	get_user_login()
#	erb :application_controller
#end

#Get user data for logging user login (via post request)
post ("/log") do
	@user = User.new(name: params["name"], email: params["email"], password: params["password"])
	@user.save
	session[:id] = @user.id
	redirect '/users/homepage'
end

#Should this code be in the homepage
post '/sessions'
	@user = User.find_by(email: params["email"], password: params["password"])
	session[:id] = @user.id
end

#Should this code be in the homepage
get '/sessions/logout'
session.clear
end


end