require 'sinatra'
require 'json'
require 'date'
#require 'pg'


get '/hello' do
	erb :homepage
end


#Get the name of the new activity to add (via post request)
post ("/create-new-activity") do
	@activity_name = params[:name]
	add_new_activity_to_json(@activity_name)
	#add_new_activity_to_sql(@activity_name)
	redirect "/hello"
end


#Don't forget to initialise the .json file with [] (this means we need to push such a file to heroku for demo day)
def add_new_activity_to_json(activity_name)
	json_string = File.read('activitylist.json')
	activities = JSON.load(json_string)
	activities << {name: activity_name}
	File.write('activitylist.json', activities.to_json)
end


#Don't forget to create the table in Heroku's postgres database
# def add_new_activity_to_sql(activity_name)	
# 	connection = PG.connect(host: "localhost")	#This needs to change when deployed on Heroku...		
# 	connection.exec("INSERT INTO activities (name) VALUES ('#{activity_name}')")	#how to write this to avoid injetion issues?			
# 	connection.close	#is a commit needed before this?
# end


# def get_all_activity_names_from_sql_table
# 	connection = PG.connect(host: "localhost")	#This needs to change when deployed on Heroku...			
# 	activity_list = connection.exec("SELECT name FROM activities")	#Gets all activity names in database
# 	full_list = []	#Use this list to store the search results to pass to HTML/erb template
	
# 	for name in activity_list				
# 		full_list << name
# 	end
	
# 	connection.close
	
# 	#DEBUGGING
# 	puts "\n\n**These are all the activity names stored**\n\n"	
# 	puts results
# 	#END OF DEBUGGING

# 	return full_list
	
# end


#Get data to log (via post request)
post ("/log") do
	@activity_logged = params[:activity_to_log]
	@minutes_spent = params[:duration]
	@date = Date.today
	log_activity_to_json(@activity_logged, @minutes_spent, @date) 
	#log_activity_to_sql(@activity_logged, @minutes_spent, @date) 
	redirect "/hello"

	#DEBUGGING STUFF: THIS PRINTS IN THE TERMINAL ONLY. DELETE WHEN NO LONGER NEEDED#
	puts "\n\t This is the date that's logged #{@date}\n\n"
	#END OF DEBUGGING#		
end


#Don't forget to initialise the .json file with [] (this means we need to push such a file to heroku for demo day)
def log_activity_to_json(activity_logged, minutes_spent, date)
	json_string = File.read('loggedactivities.json')
	activities_logged = JSON.load(json_string)
	activities_logged << {name: activity_logged, duration: minutes_spent, date: date}
	File.write('loggedactivities.json', activities_logged.to_json)
end


#Don't forget to create the table in Heroku's postgres database
# def log_activity_to_sql(activity_logged, minutes_spent, date)	
# 	connection = PG.connect(host: "localhost")	#This needs to change when deployed on Heroku...		
# 	connection.exec("INSERT INTO logged_activities (activity_name, duration, date) VALUES ('#{activity_logged}', '#{minutes_spent}', '#{date}')")	#how to write this to avoid injetion issues?			
# 	connection.close	#is a commit needed before this?
# end	



#Write a function to read the name of each activity from the activitylist JSON file

#write a function to read the date, name, duration from the loggedactivities JSONfile

