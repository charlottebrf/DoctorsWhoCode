require 'sinatra'


get '/hello' do
	erb :homepage
end


#Get the name of the new activity to add (via post request)
post ("/create-new-activity") do
	@activity_name = params[:name]	
	add_new_activity(@activity_name)
	erb :homepage
end


#This adds the new activity to a test file for now, to prove the concept
#Eventually this needs to write new activity to JSON file or database, to the correct file and field
def add_new_activity(activity_name)	
	testfile = "./check-my-stuff.txt"
	target = open(testfile, 'w')	
	target.write(activity_name)
	target.close
end


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
#not sure if I need to add in a "def" here like the above code
#need to check the below code is working, included some sample data 

require 'json'
file = File.read('loggedactivities.json')
Activities = JSON.parse(file)
end
#need to read documentation on whether this is the best place to put the json file 

Activities =[
	% : {name: "TV", minutes: "120"}
	% : {name: "coding", minutes: "45"}]


act.add(% name: "", minutes: ""})



#log activity data to JSON or database, passing in value from the get_time_spent_on_activity function
# def log_activity (activity, minutes_spent, date_time)
	# => write new activity to JSON file or database, to the correct file and field
# end
