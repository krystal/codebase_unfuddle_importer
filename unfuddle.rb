#!/usr/local/env ruby

## Imports Unfuddle Tickets into Codebase Tickets

require 'json'
require 'net/http'
require 'net/https'
require 'tempfile'
require './utils.rb'
require 'net/http/post/multipart'

# USER CONFIG BELOW #

UNFUDDLE_ACCOUNT  = '' ## Unfuddle account name
UNFUDDLE_USERNAME = '' ## Unfuddle username
UNFUDDLE_PASSWORD = '' ## Unfuddle password

CODEBASE_USERNAME = '' ## Codebase API username from profile page
CODEBASE_API_KEY  = '' ## Codebase API key from profile page
CODEBASE_PROJECT = '' ## Codebase project name to import tickets to

DEBUG = false

# Replace the five lines below with the code given to you
@status_mapping = {
}

@priority_mapping = {
}

# USER CONFIG ENDS #

def run_import
	if [UNFUDDLE_ACCOUNT, UNFUDDLE_USERNAME, UNFUDDLE_PASSWORD, CODEBASE_USERNAME, CODEBASE_API_KEY, CODEBASE_PROJECT].any? { |c| c.empty? }
		bail "Please edit the script to include your Codebase and Unfuddle credentials"
	end

	## Build a user mapping UNFUDDLE_ID => CODEBASE_ID
	codebase_users = codebase_request('/users')
	unfuddle_users = unfuddle_request('people.json')

	unless codebase_users && unfuddle_users
		puts "Could not fetch user lists. Are your credentials on the level?"
		exit
	end
	
	if @status_mapping.empty? or @priority_mapping.empty?
	  log <<-EOF

    Welcome to the Codebase Unfuddle Tickets Importer
    We will print out some code for you edit and paste in to this file. Ok?
        EOF

        continue?
    
    statuses_str = "  'new' => {
    :codebase_id => ''
    },
  'unaccepted' => {
    :codebase_id => ''
  },
  'reassigned' => {
    :codebase_id => ''
  },
  'reopened' => {
    :codebase_id => ''
  },
  'accepted' => {
    :codebase_id => ''
  },
  'resolved' => {
    :codebase_id => ''
  },
  'closed' => {
    :codebase_id => ''
  }
"
    
    priorities_str = "  '1' => {
    :codebase_id => ''
    },
  '2' => {
    :codebase_id => ''
  },
  '3' => {
    :codebase_id => ''
  },
  '4' => {
    :codebase_id => ''
  },
  '5' => {
    :codebase_id => ''
  }
"

@codebase_statuses = codebase_request("/#{CODEBASE_PROJECT}/tickets/statuses")
status_text = ''
@codebase_statuses.each do |c|
  status_text += <<-EOF
## Codebase status #{c["ticketing_status"]["name"]} has an ID of #{c["ticketing_status"]["id"]}
EOF
end

@codebase_priorities = codebase_request("/#{CODEBASE_PROJECT}/tickets/priorities")
priority_text = ''
@codebase_priorities.each do |p|
  priority_text += <<-EOF
## Codebase priority #{p["ticketing_priority"]["name"]} has an ID of #{p["ticketing_priority"]["id"]}
EOF
end
        
log <<-EOF

Paste this code in to unfuddle.rb, adding the codebase id's as above:

#{status_text}
@status_mapping = {
#{statuses_str}}

#{priority_text}
@priority_mapping = {
#{priorities_str}}
EOF
        log 'Once you have done this, rerun this file.'
            bail 'If you are seeing the message several times, make sure you have pasted the code correctly.'
	end
	
	
	
	
	

	user_map = unfuddle_users.inject(Hash.new) do |memo, unfuddle_user| 
		# Find a user in Codebase with the same email address
		codebase_user = codebase_users.select {|user| user["user"]["email_address"] == unfuddle_user["email"] }.first
		memo[unfuddle_user["id"]] = codebase_user["user"]["id"] if codebase_user
		memo
	end

	unfuddle_projects = unfuddle_request('projects.json')
	return unless unfuddle_projects
	
	unfuddle_projects.each do |unfuddle_project|
		discussions_page = 1
		begin
			unfuddle_tickets = unfuddle_request("projects/#{unfuddle_project["id"]}/tickets.json?page=#{discussions_page}")
			return unless unfuddle_tickets
       
			unfuddle_tickets.each do |unfuddle_ticket|
				codebase_payload = {
				  :ticket => {
				    :summary => unfuddle_ticket["summary"], 
				    :description => unfuddle_ticket["description"], 
				    :created_at => unfuddle_ticket["created_at"], 
				    :updated_at => unfuddle_ticket["updated_at"], 
				    :priority_id => @priority_mapping[unfuddle_ticket["priority"]][:codebase_id],
				    :status_id => @status_mapping[unfuddle_ticket["status"]][:codebase_id],
				  }
				}
				if codebase_user_id = user_map[unfuddle_ticket["reporter_id"]]
					codebase_payload[:ticket][:user_id] = codebase_user_id
				else					
					codebase_payload[:ticket][:author_name] = "Unfuddle Importer"
					codebase_payload[:ticket][:author_email] = ""
				end
				
				## Create ticket in codebase
				codebase_discussion = codebase_request("/#{CODEBASE_PROJECT}/tickets", :post, codebase_payload)
				
				## Check for attachments
				unfuddle_project_attachments = unfuddle_request("projects/#{unfuddle_project["id"]}/tickets/#{unfuddle_ticket["id"]}/attachments.json")
				if unfuddle_project_attachments
				  unfuddle_project_attachments.each do |unfuddle_project_attachment|
				    
				    ## fetch attachment 
				    attachment = unfuddle_request("projects/#{unfuddle_project["id"]}/tickets/#{unfuddle_ticket["id"]}/attachments/#{unfuddle_project_attachment["id"]}/download")
				    file = Tempfile.new(unfuddle_project_attachment["filename"])
            begin
              file.write(attachment)
              file.rewind    
              url = URI.parse("http://api3.codebasehq.com/#{CODEBASE_PROJECT}/tickets/#{codebase_discussion["ticket"]["ticket_id"]}/attachments")
              
              File.open(file.path) do |attach|
                req = Net::HTTP::Post::Multipart.new url.path, "ticket_attachment[description]" => "Unfuddle Import", "ticket_attachment[attachment]" => UploadIO.new(attach, "#{unfuddle_project_attachment["content_type"]}", "#{unfuddle_project_attachment["filename"]}")
                req.basic_auth(CODEBASE_USERNAME, CODEBASE_API_KEY)
                res = Net::HTTP.start(url.host, url.port) do |http|
                  http.request(req)
                end
              end
              
            ensure
               file.close
               file.unlink
            end
				  end
				end
        
        unfuddle_comments = unfuddle_request("projects/#{unfuddle_project["id"]}/tickets/#{unfuddle_ticket["id"]}/comments.json")
        return unless unfuddle_comments
        
        unfuddle_comments.each do |unfuddle_comment|          
          codebase_payload = {
  				  :ticket_note => {
  				    :content => unfuddle_comment["body"],
  				    :created_at => unfuddle_comment["created_at"], 
  				    :updated_at => unfuddle_comment["updated_at"]
  				  }
  				}
  				
  				if codebase_user_id = user_map[unfuddle_comment["author_id"]]
  					codebase_payload[:ticket_note][:user_id] = codebase_user_id
  				else					
  					codebase_payload[:ticket_note][:author_name] = "Unfuddle Importer"
  					codebase_payload[:ticket_note][:author_email] = ""
  				end
  				codebase_note = codebase_request("/#{CODEBASE_PROJECT}/tickets/#{codebase_discussion["ticket"]["ticket_id"]}/notes", :post, codebase_payload)
  				
  				## Check for attachments
  				unfuddle_comment_attachments = unfuddle_request("projects/#{unfuddle_project["id"]}/tickets/#{unfuddle_ticket["id"]}/comments/#{unfuddle_comment["id"]}/attachments.json")
  				if unfuddle_comment_attachments
  				  unfuddle_comment_attachments.each do |unfuddle_comment_attachment|
  				    ## fetch attachment 
  				    attachment = unfuddle_request("projects/#{unfuddle_project["id"]}/tickets/#{unfuddle_ticket["id"]}/comments/#{unfuddle_comment['id']}/attachments/#{unfuddle_comment_attachment["id"]}/download")
  				    file = Tempfile.new(unfuddle_comment_attachment["filename"])
              begin
                file.write(attachment)
                file.rewind    
                url = URI.parse("http://api3.codebasehq.com/#{CODEBASE_PROJECT}/tickets/#{codebase_discussion["ticket"]["ticket_id"]}/attachments")

                File.open(file.path) do |attach|
                  req = Net::HTTP::Post::Multipart.new url.path, "ticket_attachment[description]" => "Unfuddle Import", "ticket_attachment[attachment]" => UploadIO.new(attach, "#{unfuddle_comment_attachment["content_type"]}", "#{unfuddle_comment_attachment["filename"]}")
                  req.basic_auth(CODEBASE_USERNAME, CODEBASE_API_KEY)
                  res = Net::HTTP.start(url.host, url.port) do |http|
                    http.request(req)
                  end
                end

              ensure
                 file.close
                 file.unlink
              end
  				  end
  				end
  				
        end
			end

			discussions_page += 1
		end while unfuddle_tickets.length > 0
	end
end

def codebase_request(path, type = :get, payload = nil)
	if type == :get
		req = Net::HTTP::Get.new(path)
	elsif type == :post
		req = Net::HTTP::Post.new(path)
	end

	req.basic_auth(CODEBASE_USERNAME, CODEBASE_API_KEY)
	req['Content-Type'] = 'application/json'
	req['Accept'] = 'application/json'

	if payload && payload.respond_to?(:to_json)
		req.body = payload.to_json
		puts req.body if DEBUG
	end


	if ENV["DEVELOPMENT"]
		res = Net::HTTP.new("api3.codebase.dev", 80)
	else
		res = Net::HTTP.new("api3.codebasehq.com", 443)
		res.use_ssl = true
		res.verify_mode = OpenSSL::SSL::VERIFY_NONE
	end

	request(res, req)
end

def unfuddle_request(path)
	prefix_path = "/api/v1/"
	path = prefix_path + path

	req = Net::HTTP::Get.new(path);
	req.basic_auth(UNFUDDLE_USERNAME, UNFUDDLE_PASSWORD)

	res = Net::HTTP.new("#{UNFUDDLE_ACCOUNT}.unfuddle.com", 443)
	res.use_ssl = true
	res.verify_mode = OpenSSL::SSL::VERIFY_NONE

	request(res, req)
end

def request(res, req)
	puts "Requesting #{req.path}" if DEBUG
	case result = res.request(req)
	when Net::HTTPSuccess
		#json decode
		if result.body.valid_json?
		  return JSON.parse(result.body)
		else
		  return result.body
		end		
	else
		puts result
		puts "Sorry, that request failed."
		puts result.body
		return false
	end
end

class String
  def valid_json?
    begin
      JSON.parse(self)
      return true
    rescue Exception => e
      return false
    end
  end
end

run_import