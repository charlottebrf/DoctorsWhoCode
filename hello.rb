require 'sinatra'
require 'json'
require 'date'
require 'chartkick'


get '/hello' do
	log_file = 'loggedactivities.json'
	@log_entries = get_data_from_json_file(log_file)
	@date = Date.today.to_s



#TEST *** Create array variable to pass to bar chart function
	today = Date.today.to_s 	#converted to string so it can be compared with hash contents
	@todays_raw_data = []
	
	for entry in @log_entries		
		if entry["date"] == today		
			activity = entry["name"]
			minutes = entry["duration"].to_i			
			#@todays_raw_data << {activity => minutes}

			@todays_raw_data = {activity => minutes}
		end		
	end
 		
	#need a handler for if today's data is empty

	#DEBUGGING
	@log_entries.each do |item|
  		puts "\nI did #{item["duration"]} minutes of #{item["name"]}\n"
	end

	puts "\n\n\n ****\nToday is #{today}. There are no activities logged today. See? \n\n This is today's data #{@todays_raw_data}\n\n"
 	puts "Here's what's in the JSON file:\n #{@log_entries}\n****\n\n\n"		
	#END OF DEBUGGING

	erb :homepage
end


#Get data to log (via post request)
post ("/log") do
	@activity_logged = params[:activity_to_log]
	@minutes_spent = params[:duration]
	@date = Date.today
	log_activity_to_json(@activity_logged, @minutes_spent, @date) 
	redirect "/hello"
end


#Don't forget to initialise the .json file with [] (this means we need to push such a file to heroku for demo day)
def log_activity_to_json(activity_logged, minutes_spent, date)
	json_string = File.read('loggedactivities.json')
	activities_logged = JSON.load(json_string)
	activities_logged << {name: activity_logged, duration: minutes_spent, date: date}
	File.write('loggedactivities.json', activities_logged.to_json)
end


#Get JSON file data and put it in a Ruby hash
def get_data_from_json_file(filename)
	file_to_parse = File.read(filename)
	data_hash = JSON.parse(file_to_parse)
	return data_hash
end

