require 'sinatra'

get '/hello' do
	erb :homepage
end

#Get the name of the new activity to add
# get ("/create-new-activity") do	#this path should be defined on the html submit form

	# => how do i indicate a post method for HTML above
	# => get html form data with equivalent of request.post
	# => @new_activity = [data from request.post]
	# => add_new_activity(new_activity) # => write new activity to JSON file or database (should be a separate function, so you can sub out JSON for database. pass in new_activity value)
	# => erb: home
# end


#Add the new activity name to JSON or SQL
# def add_new_activity(new_activity)
	# => write new activity to JSON file or database, to the correct file and field
# end


#Get the name of the activity and minutes spent on it
# get ("/time-spent-on-activity") do
	# => how do i indicate a post method for HTML above
	# => get html form data with equivalent of request.post
	# => @date_time = [ruby function for date, either date or date time]
	# => @minutes_spent = [data from request.post]
	# => @activity = [data from request.post]
	# => log_activity(activity, minutes_spent, date_time) # => log to JSON file or database (should be a separate function, so you can sub out JSON for database. pass in new_activity value)
	# erb :home 
# end


#log activity data to JSON or database, passing in value from the get_time_spent_on_activity function
# def log_activity (activity, minutes_spent, date_time)
	# => write new activity to JSON file or database, to the correct file and field
# end
