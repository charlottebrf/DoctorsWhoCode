require 'sinatra'
require 'json'
require 'date'
require 'chartkick'
require 'oauth'


##STUFF TO BLOCK PAGE ACCESS IF USER NOT SIGNED IN##

configure do
  enable :sessions
end


helpers do
  def authorised?
    session[:authorised]
  end
end

##END OF STUFF##


get '/' do
    erb :startpage
end


get '/login' do

	#DISPLAY APP'S TWITTER AUTHORIZATION PAGE

	consumer_key = "8aLsCR1VgiOHWQ5GmiGhPYrqG"	
	consumer_secret = "cYcZsp8sCh9bR0MDbhyPr51uWajq0GGopOrnEOOiBL1s2eq7nT"
	callback_url = "http://evening-lowlands-39707.herokuapp.com/homepage"	#Where to take them when login successful

	oauth = OAuth::Consumer.new(consumer_key, consumer_secret, {:site => "https://twitter.com"})

	request_token = oauth.get_request_token(:oauth_callback => callback_url)
	session[:token] = request_token.token
	session[:secret] = request_token.secret

	redirect request_token.authorize_url	# Sends user to Twitter to be authenticated

	#END OF PURE DISPLAY SECTION

	#DOES THIS ONLY HAPPEN WITH SUCCESSFUL LOGIN?
	session[:authorised] = true 

	# Your callback URL will now get a request that contains an oauth_verifier. 
	# Use this and the request token from earlier to construct an access request.
	request_token = OAuth::RequestToken.new(oauth, session[:request_token], session[:request_token_secret])
	access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])

	# Get account details from Twitter
	@twitter_details = oauth.request(:get, '/account/verify_credentials.json', access_token, {:scheme => :query_string})

   # erb :login
end


get '/logout' do
  session[:authorised] = nil
  redirect "https://twitter.com/"
  #erb :notloggedin
end


get '/homepage' do	
	halt erb(:notloggedin) unless authorised?
	get_today_summary_data()
	@autocomplete_suggestions = get_autocomplete_suggestions()
	erb :homepage
end


get '/week' do
	halt erb(:notloggedin) unless authorised?
	get_week_summary_data()	
	erb :week
end


get '/month' do
	halt erb(:notloggedin) unless authorised?
	get_month_summary_data()	
	erb :month
end


#Get user data for logging (via post request)
post ("/log") do
	@activity_logged = params[:activity_to_log]
	@minutes_spent = params[:duration]
	@type = params[:task_type]
	@date = Date.today
	log_activity_to_json(@activity_logged, @minutes_spent, @date, @type) 
	redirect "/homepage"
end


#Don't forget to initialise the .json file with [] (this means we need to push such a file to heroku for demo day)
def log_activity_to_json(activity_logged, minutes_spent, date, type)
	json_string = File.read('loggedactivities.json')
	activities_logged = JSON.load(json_string)
	activities_logged << {name: activity_logged, duration: minutes_spent, date: date, type: type}
	File.write('loggedactivities.json', activities_logged.to_json)
end


#Get JSON file data and put it in a Ruby hash
def get_data_from_json_file(filename)
	file_to_parse = File.read(filename)
	data_hash = JSON.parse(file_to_parse)
	return data_hash
end


def get_autocomplete_suggestions	
	log_file = 'loggedactivities.json'
	data_hash = get_data_from_json_file(log_file)
	autocomplete_suggestions = data_hash.uniq { |row| row["name"] }
	return autocomplete_suggestions
end


#Get log data from today and prepare it for graph/summary in erb file
def get_today_summary_data
	log_file = 'loggedactivities.json'
	@log_entries = get_data_from_json_file(log_file)
	today = Date.today.to_s 	#convert to string so it can be compared with hash contents
	@todays_graph_data = {}
	@todays_text_data = {}
	all_activities_entered_today =[]
	interim_activity_list = []	#intermediate step so we can up up all durations for a single activity

	for entry in @log_entries		
		if entry["date"] == today
			all_activities_entered_today << {"name" => entry["name"], "duration" => entry["duration"].to_i}	
 			interim_activity_list << {"name" => entry["name"], "duration" => 0}			
		end		
	end

	day_summary_of_unique_activities = interim_activity_list.uniq { |row| row["name"] }	#creates list of unique activities based on name

	for entry in day_summary_of_unique_activities

		for item in all_activities_entered_today

			if entry["name"] == item["name"]
				
				#DEBUGGING#
				#This should find a match for every activity plus each duplicate
				puts "\n\n***IT'S A MATCH!***"
				puts "The activity \"#{entry["name"]}\" in the list of distinct activities matched with \"#{item["name"]}\" in the log file for today."
				puts "Add #{item["duration"]} minutes to the running total of #{entry["duration"]} minutes."
				#END OF DEBUGGING#

				#Adds to duration for every value/duplicate value found
				entry["duration"] += item["duration"]
				
				#DEBUGGING#
				puts "Today's new total for \"#{entry["name"]}\" is  #{entry["duration"]} minutes"
				#END OF DEBUGGING#

			end

		end

	end

	#remap hashes to name=>duration pairs
	for entry in day_summary_of_unique_activities
		day_summary_of_unique_activities.each{|k,v| @todays_graph_data[entry["name"].upcase]=entry["duration"].to_i}		
		day_summary_of_unique_activities.each{|k,v| @todays_text_data[entry["name"]]=entry["duration"].to_i}
	end
 		
 	@graph_data = @todays_graph_data.sort_by { |k,v| -v} 
 	@text_data = @todays_text_data.sort_by { |k,v| -v} 
 	@most_time_spent = @text_data[0]
 	@least_time_spent = @text_data[-1] 	

 	#debugging#
 	puts "\n\n\n***** JSON, hash, and array debugging *****"
 	puts "\n ALL JSON LOG ENTRIES:\n#{@log_entries}"
 	puts "\n Todays Raw Data:\n#{all_activities_entered_today}"
 	puts "\n interim_activity_list:\n#{interim_activity_list}"
 	puts "\n Today time spent on activities today:\n#{day_summary_of_unique_activities}"
 	puts "\n TODAY'S LOGGED GRAPH DATA:\n#{@todays_graph_data}"
 	puts "\n TODAY'S LOGGED TEXT DATA:\n#{@todays_text_data}"
 	puts "\n SORTED GRAPH DATA:\n#{@graph_data}"
 	puts "\n SORTED TEXT DATA:\n#{@text_data}"
 	puts "\n\n\n"
	#end of debugging#

end


def get_week_summary_data
	log_file = 'loggedactivities.json'
	@log_entries = get_data_from_json_file(log_file)
	now = Date.today
	today = now.to_s
	a_week_ago = (now-7).to_s 	
	@week_graph_data = {}
	@week_text_data = {}
	all_activities_entered_week =[]
	interim_activity_list = []	

	for entry in @log_entries		
		if (entry["date"] <= today) && (entry["date"] >= a_week_ago)
			all_activities_entered_week << {"name" => entry["name"], "duration" => entry["duration"].to_i}	
 			interim_activity_list << {"name" => entry["name"], "duration" => 0}			
		end		
	end

	week_summary_of_unique_activities = interim_activity_list.uniq { |row| row["name"] }

	for entry in week_summary_of_unique_activities
		for item in all_activities_entered_week
			if entry["name"] == item["name"]								
				entry["duration"] += item["duration"]				
			end
		end
	end

	for entry in week_summary_of_unique_activities
		week_summary_of_unique_activities.each{|k,v| @week_graph_data[entry["name"].upcase]=entry["duration"].to_i}		
		week_summary_of_unique_activities.each{|k,v| @week_text_data[entry["name"]]=entry["duration"].to_i}
	end
 		
 	@graph_data_week = @week_graph_data.sort_by { |k,v| -v} 
 	@text_data_week = @week_text_data.sort_by { |k,v| -v} 
 	@most_time_spent_week = @text_data_week[0]
 	@least_time_spent_week = @text_data_week[-1] 	
end


def get_month_summary_data
	log_file = 'loggedactivities.json'
	@log_entries = get_data_from_json_file(log_file)
	now = Date.today
	today = now.to_s
	a_month_ago = (now-30).to_s 	
	@month_graph_data = {}
	@month_text_data = {}
	all_activities_entered_month =[]
	interim_activity_list = []	

	for entry in @log_entries		
		if (entry["date"] <= today) && (entry["date"] >= a_month_ago)
			all_activities_entered_month << {"name" => entry["name"], "duration" => entry["duration"].to_i}	
 			interim_activity_list << {"name" => entry["name"], "duration" => 0}			
		end		
	end

	month_summary_of_unique_activities = interim_activity_list.uniq { |row| row["name"] }

	for entry in month_summary_of_unique_activities
		for item in all_activities_entered_month
			if entry["name"] == item["name"]								
				entry["duration"] += item["duration"]				
			end
		end
	end

	for entry in month_summary_of_unique_activities
		month_summary_of_unique_activities.each{|k,v| @month_graph_data[entry["name"].upcase]=entry["duration"].to_i}		
		month_summary_of_unique_activities.each{|k,v| @month_text_data[entry["name"]]=entry["duration"].to_i}
	end
 		
 	@graph_data_month = @month_graph_data.sort_by { |k,v| -v} 
 	@text_data_month = @month_text_data.sort_by { |k,v| -v} 
 	@most_time_spent_month = @text_data_month[0]
 	@least_time_spent_month = @text_data_month[-1] 	
end