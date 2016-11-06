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
	today = Date.today.to_s 	#converted to string so it can be compared with hash contents
	@todays_graph_data = {}
	@todays_text_data = {}

	
	for entry in @log_entries		
		if entry["date"] == today
			#this deletes duplicates!						
			@log_entries.each{|k,v| @todays_graph_data[entry["name"].upcase]=entry["duration"].to_i}		#remaps hash to name=>duration pairs
			@log_entries.each{|k,v| @todays_text_data[entry["name"]]=entry["duration"].to_i}		#remaps hash to name=>duration pairs
		end		
	end
 		
 	@graph_data = @todays_graph_data.sort_by { |k,v| -v} 
 	@text_data = @todays_text_data.sort_by { |k,v| -v} 
 	@most_time_spent = @text_data[0]
 	@least_time_spent = @text_data[-1] 	

 	#debugging#
 	puts "\n\n\n***** JSON, hash, and array debugging *****"
 	puts "\n ALL JSON LOG ENTRIES:\n\n#{@log_entries}"
 	puts "\n TODAY'S LOGGED DATA:\n\n#{@todays_graph_data}"
 	puts "\n SORTED GRAPH DATA:\n\n#{@graph_data}"
 	puts "\n\n\n"
	#end of debugging#

end

