require 'sinatra'
require 'json'
require 'date'
require 'chartkick'


get '/hello' do
	get_summary_data()
	erb :homepage
end


#Get user data for logging (via post request)
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


#Get log data from today and prepare it for graph/summary in erb file
def get_summary_data
	log_file = 'loggedactivities.json'
	@log_entries = get_data_from_json_file(log_file)
	today = Date.today.to_s 	#convert to string so it can be compared with hash contents
	@todays_graph_data = {}
	@todays_text_data = {}


	todays_raw_data =[]			#test code
	interim_activity_list = []	#intermediate step to enable summing of activity durations

	
	for entry in @log_entries		
		if entry["date"] == today

			todays_raw_data << {"name" => entry["name"], "duration" => entry["duration"].to_i}	
 			interim_activity_list << {"name" => entry["name"], "duration" => 0}			

			#this deletes duplicates!						
			@log_entries.each{|k,v| @todays_graph_data[entry["name"].upcase]=entry["duration"].to_i}		#remaps hash to name=>duration pairs
			@log_entries.each{|k,v| @todays_text_data[entry["name"]]=entry["duration"].to_i}		#remaps hash to name=>duration pairs
		end		
	end

	day_summary_unique = interim_activity_list.uniq { |row| row["name"] }

	for entry in day_summary_unique

		for item in todays_raw_data

			if entry["name"] == item["name"]
				
				#DEBUGGING#
				#This should find a match for every activity plus each duplicate
				puts "\n\n***IT'S A MATCH!***"
				puts "The activity \"#{entry["name"]}\" in the list of distinct activities matched with \"#{item["name"]}\" in the log file for today."
				puts "Add #{item["duration"]} minutes to the running total of #{entry["duration"]} minutes."
				#END OF DEBUGGING#

				#Increases duration for every duplicate value
				entry["duration"] += item["duration"]
				
				#DEBUGGING#
				puts "Today's new total for \"#{entry["name"]}\" is  #{entry["duration"]} minutes"
				#END OF DEBUGGING#

			end

		end

	end
 		
 	@graph_data = @todays_graph_data.sort_by { |k,v| -v} 
 	@text_data = @todays_text_data.sort_by { |k,v| -v} 
 	@most_time_spent = @text_data[0]
 	@least_time_spent = @text_data[-1] 	

 	#debugging#
 	puts "\n\n\n***** JSON, hash, and array debugging *****"
 	puts "\n Todays Raw Data:\n#{todays_raw_data}"
 	puts "\n interim_activity_list:\n#{interim_activity_list}"
 	puts "\n day_summary_unique:\n#{day_summary_unique}"
 	puts "\n ALL JSON LOG ENTRIES:\n#{@log_entries}"
 	puts "\n TODAY'S LOGGED GRAPH DATA:\n#{@todays_graph_data}"
 	puts "\n TODAY'S LOGGED TEXT DATA:\n#{@todays_text_data}"
 	puts "\n SORTED GRAPH DATA:\n#{@graph_data}"
 	puts "\n\n\n"
	#end of debugging#

end

