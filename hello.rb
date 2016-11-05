require 'sinatra'
require 'json'
require 'date'
require 'chartkick'
#require 'pg'


get '/hello' do
	log_file = 'loggedactivities.json'
	@log_entries = get_data_from_json_file(log_file)
	@date = Date.today.to_s


	#DEBUGGING
	@log_entries.each do |item|
  		puts "\nI did #{item["duration"]} minutes of #{item["name"]}\n"
  		puts "I am here #{{@today}}"
	end
	#END OF DEBUGGING

	erb :homepage
end


#Get data to log (via post request)
post ("/log") do
	@activity_logged = params[:activity_to_log]
	@minutes_spent = params[:duration]
	@date = Date.today
	log_activity_to_json(@activity_logged, @minutes_spent, @date) 
	#log_activity_to_sql(@activity_logged, @minutes_spent, @date) 
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



#function for extracting info for daily summary
#how do you empty the file when it is no longer today? Or does the code do that implicitly here?
# get "/prepare_summary_info" do #change to def prepare_summary_info

# 	log_file = 'loggedactivities.json'
# 	@log_entries = get_data_from_json_file(log_file)
# 	today = Date.today.to_s 	#converted to string so it can be compared with hash contents
# 	todays_raw_data = []
# 	interim_activity_list = []

# 	for entry in @log_entries		
# 		if entry["date"] == today		
# 			todays_raw_data << {name: entry["name"], duration: entry["duration"]}	
# 			interim_activity_list << {name: entry["name"], duration: 0}			
# 		end	
# 	end

# 	if todays_raw_data.empty?		
# 		@entries = "none" #Pass .erb file to handle graph and text summaries if nothing is logged yet

# 		#DEBUGGING		
# 		puts "\n\n\n ****\nToday is #{today}. There are no activities logged today. See? #{todays_raw_data}\n\n"
# 		puts "Here's what's in the JSON file:\n #{@log_entries}\n****\n\n\n"		
# 		#END OF DEBUGGING

# 	else
# 		#Build a hash containing only unique name values, with durations all set to zero
# 		day_summary = interim_activity_list.uniq { |row| row[:name] }
		
# 		#take day summary
# 		#iterate through today's raw data
# 		#if the name in the raw data iteration matches the name of the day summary, take the value for the name key in 
# 		#day summary and add (NOT overwrite) the value from today's raw data


# #		for unique_activity in day_summary
# 			for row in todays_raw_data		
# 				if row["name"].to_s == day_summary["name"].to_s		#If there's at least one entry for that activity name
# 					puts "YES!"
# 					puts todays_raw_data
# 					#duration_to_add = raw_activity["duration"].to_i			#how to convert to int?					
# 					#puts "\n#{duration_to_add}"
# 					#cumulative_duration = unique_activity["duration"]	#how to convert to int?
# 					#updated_duration = duration_to_add + cumulative_duration
# 					#unique_activity["duration"] = updated_duration
# 				end
# 			end	
# #		end



# 		#DEBUGGING
# 		puts "\n\n\n **********\nToday is #{today}. Here's what was logged:\n\n#{todays_raw_data}\n\n"
# 		puts "Based on above, is this a unique array?\n\n #{day_summary}\n\n"
# 		puts "This is the file that we'll populate with durations. #{interim_activity_list}\n\n"
# 		puts "Here's what's in the JSON file:\n #{@log_entries}\n****\n\n\n"
# 		puts "\n\n\nThis should be a summary #{day_summary}\n****\n\n\n"

# 		#END OF DEBUGGING

# 	end

# end



	#iterate through info from log hash, and if an activity name match is found, take the duration value from the info hash and add it to the unique name in daily summary hash

#http://stackoverflow.com/questions/10221455/how-to-sum-json-array

	#return todays_raw_data








#iterating and summing json:
#http://stackoverflow.com/questions/26661057/combine-like-json-properties-and-sum-values
#http://stackoverflow.com/questions/11199653/javascript-sum-and-group-by-of-json-data
#http://stackoverflow.com/questions/24682409/json-summing-multiple-objects-where-values-contain-a-string

#Don't forget to create the table in Heroku's postgres database
# def log_activity_to_sql(activity_logged, minutes_spent, date)	
# 	connection = PG.connect(host: "localhost")	#This needs to change when deployed on Heroku...		
# 	connection.exec("INSERT INTO logged_activities (name, duration, date) VALUES ('#{activity_logged}', '#{minutes_spent}', '#{date}')")	#how to write this to avoid injetion issues?			
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
# 	puts full_list
# 	#END OF DEBUGGING

# 	return full_list
	
# end