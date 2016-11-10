require 'sinatra'
require 'omniauth-twitter'
require 'json'
require 'chartkick'
require 'oauth'


use OmniAuth::Builder do
  provider :twitter, '8aLsCR1VgiOHWQ5GmiGhPYrqG', 'cYcZsp8sCh9bR0MDbhyPr51uWajq0GGopOrnEOOiBL1s2eq7nT',
  {:authorize_params => {
    :force_login => 'true'
    }
  }
end


configure do
  enable :sessions
end


helpers do
  def admin?
    session[:admin]
  end
end


get '/' do
  if admin?
    redirect to("/homepage")
  else
    erb :startpage
  end
end


get '/login' do
  redirect to("/auth/twitter?x_auth_access_type=read")
end


get '/auth/twitter/callback' do
  session[:admin] = true     
  #If you halt and restart Ruby, these values get lost when pages are refreshed. Could be an issue if user never logs out and servers go to sleep
  $user_name = env['omniauth.auth']['info']['name']
  $user_id = env['omniauth.auth']['uid']
  redirect to("/homepage")
end


get '/auth/failure' do
  params[:message]
end


get '/homepage' do
  halt erb(:notauth) unless admin?
  get_today_summary_data()
  get_target_data()
  @autocomplete_suggestions = get_autocomplete_suggestions()
  erb :homepage
end


get '/week' do
  halt erb(:notauth) unless admin?
  get_week_summary_data() 
  erb :week
end


get '/month' do
  halt erb(:notauth) unless admin?
  get_month_summary_data()  
  erb :month
end


get '/targets' do
  halt erb(:notauth) unless admin?
  @autocomplete_suggestions = get_autocomplete_suggestions()
  get_target_data()
  erb :targets
end


post ('/settarget') do
  @target_activity = params[:target_activity]
  puts "\n\n\n #{@target_activity}"
  @target_minutes = params[:target_minutes]
  @period = params[:period]
  log_targets_to_json(@target_activity, @target_minutes, @period) 
  redirect "/targets"
end


post ('/deletetarget') do
  data_hash = get_data_from_json_file("targets.json")
  data_for_target_to_delete = params[:delete_target].split(%r{,\s*})  
  for entry in data_hash
    if entry["target_activity"] == data_for_target_to_delete[1]
      @updated_target_list = data_hash.delete_if { |h| h["target_activity"] == data_for_target_to_delete[1] }
    end
  end  
  write_updated_target_list_to_json(@updated_target_list)
  redirect "/targets"
end


get '/logout' do
  session[:admin] = nil
  erb :signedout
end


#Get user data for logging (via post request)
post ("/log") do
  @user = $user_id.to_s
  @activity_logged = params[:activity_to_log]
  @minutes_spent = params[:duration]
  @type = params[:task_type]
  @date = Date.today
  log_activity_to_json(@user, @activity_logged, @minutes_spent, @date, @type) 
  redirect "/homepage"
end


#Don't forget to initialise the .json file with [] (this means we need to push such a file to heroku for demo day)
def log_targets_to_json(target_activity, target_minutes, period)
  json_string = File.read('targets.json')
  targets_set = JSON.load(json_string)
  targets_set << {user: $user_id, target_activity: target_activity, target_minutes: target_minutes, period: period}
  File.write('targets.json', targets_set.to_json)
end

def write_updated_target_list_to_json(new_list)
  json_string = File.read('targets.json')
  File.write('targets.json', new_list.to_json)
end


#Don't forget to initialise the .json file with [] (this means we need to push such a file to heroku for demo day)
def log_activity_to_json(user, activity_logged, minutes_spent, date, type)
  json_string = File.read('loggedactivities.json')
  activities_logged = JSON.load(json_string)
  activities_logged << {user: user, name: activity_logged, type: type, duration: minutes_spent, date: date}
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
  my_activities_only = []
  for entry in data_hash
    if entry["user"] == $user_id
      my_activities_only << {"user" => entry["user"], "name" => entry["name"], "type" => entry["type"], "duration" => entry["duration"], "date" => entry["date"]}
    end
  end
  autocomplete_suggestions = my_activities_only.uniq { |row| row["name"] }   
  return autocomplete_suggestions 
end


#Get log data from today and prepare it for graph/summary in erb file
def get_today_summary_data
  log_file = 'loggedactivities.json'
  @log_entries = get_data_from_json_file(log_file)
  today = Date.today.to_s   #convert to string so it can be compared with hash contents
  @todays_graph_data = {}
  @todays_text_data = {}
  all_activities_entered_today =[]
  interim_activity_list = []  #intermediate step so we can up up all durations for a single activity
  for entry in @log_entries   
    if (entry["date"] == today) && (entry["user"] == $user_id)
      all_activities_entered_today << {"name" => entry["name"], "duration" => entry["duration"].to_i} 
      interim_activity_list << {"name" => entry["name"], "duration" => 0}     
    end   
  end
  day_summary_of_unique_activities = interim_activity_list.uniq { |row| row["name"] } #creates list of unique activities based on name
  for entry in day_summary_of_unique_activities
    for item in all_activities_entered_today
      if entry["name"] == item["name"]            
        entry["duration"] += item["duration"]         #Adds to duration for every value/duplicate value found
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
    if ((entry["date"] <= today) && (entry["date"] >= a_week_ago)) && (entry["user"] == $user_id)
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
    if ((entry["date"] <= today) && (entry["date"] >= a_month_ago)) && (entry["user"] == $user_id)
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


def get_target_data
  target_file = 'targets.json'
  @target_entries = get_data_from_json_file(target_file)

  @day_targets = []
  @week_targets = []  
  @month_targets = []

  for entry in @target_entries   
    if (entry["user"] == $user_id) && (entry["period"] == "day")
      @day_targets << {"user" => entry["user"], "target_activity" => entry["target_activity"], "target_minutes" => entry["target_minutes"], "period" => entry["period"]}
    end   
    if (entry["user"] == $user_id) && (entry["period"] == "week")
      @week_targets << {"user" => entry["user"], "target_activity" => entry["target_activity"], "target_minutes" => entry["target_minutes"], "period" => entry["period"]}
    end  
    if (entry["user"] == $user_id) && (entry["period"] == "month")
      @month_targets << {"user" => entry["user"], "target_activity" => entry["target_activity"], "target_minutes" => entry["target_minutes"], "period" => entry["period"]}
    end  
  end

end