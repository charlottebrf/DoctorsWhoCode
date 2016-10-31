require 'sinatra'
require 'json'
require 'date'


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
#Don't forget to initialise the .json file with [] 
def add_new_activity(activity_name)
	json_string = File.read('activitylist.json')
	activities = JSON.load(json_string)
	activities << {name: activity_name}
	File.write('activitylist.json', activities.to_json)

end


#Get the name of the activity and minutes spent on it
post ("/log") do
	@activity_logged = params[:activity_to_log]
	@minutes_spent = params[:duration]
	@date = Date.today
	log_activity(@activity_logged, @minutes_spent, @date) 
	erb :homepage
end

def log_activity(activity_logged, minutes_spent, date)
	json_string = File.read('loggedactivities.json')
	activities_logged = JSON.load(json_string)
	activities_logged << {name: activity_logged, duration: minutes_spent, date: date}
	File.write('loggedactivities.json', activities_logged.to_json)

end

	
