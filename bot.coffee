#########################
## DEPENDENCIES        ##
#########################

Slack 		= require 'slack-client'
Client 		= require('node-rest-client').Client
client 		= new Client()
_ 			= require 'lodash'
moment 		= require 'moment'
r 			= require 'rethinkdb'

#########################
## SLACK OPTIONS       ##
#########################

slackToken = 'YOUR-SLACK-TOKEN-GOES-HERE' # Add a bot at https://my.slack.com/services/new/bot and copy the token here.
autoReconnect = true # Automatically reconnect after an error response from Slack.
autoMark = true # Automatically mark each message as read after it is processed.
slack = new Slack(slackToken, autoReconnect, autoMark)

#########################
## BOT OPTIONS         ##
#########################

options = {
	## Bot is on if this is set to true, if false, will not respond to commands
	is_running : true
}

#########################
## HELPER FUNCTIONS    ##
#########################

## Used for displaying message info in a nice format to the server
messageInfo = (info) ->
	console.log '\n==============='
	console.log 'Sender: ' + info.sender
	console.log 'Is Admin: ' + info.is_admin
	console.log 'Text: ' + info.text
	if _.has(info.channel, 'name')
		console.log 'Channel: ' + info.channel.name
	else
		console.log 'Channel: PRIVATE MESSAGE' 
	console.log 'Time: ' + new Date
	console.log 'Is running: ' + options.is_running
	console.log '===============\n'

## Commands with 1 argument
cmd = (command, info, zombie, callback) ->
	## Only execute command if bot is running or the zombie parameter is set to true
	if options.is_running || zombie 
		## If message content is equal to the command, proceed with callback
		if info.text == command
			callback()

## Commands that only work in blog channel
blog = (info, zombie, callback) ->
	if options.is_running || zombie
		## Verify the message is from a channel (excludes private messages)
		if _.has(info.channel, 'name')
			## Verify the message is from the channel with the name `blog`
			if info.channel.name == 'blog'
				callback()



## Setup connection variable for later use
connection = null

## Connect to RethinkDB then open Slack
r.connect
	host: "localhost"
	port: 28015
, (err, conn) ->
	throw err  if err
	connection = conn
	console.log('Connected to database successfully.')
	
	## Create table in database if it doesn't already exist
	r.db('test').tableCreate('posts').run connection, (err, result) ->
		## Log info for troubleshooting
		console.log JSON.stringify(result, null, 2)

	#########################
	## SLACK OPENED        ##
	#########################

	slack.on 'open', ->
		channels = []
		# Get all the channels that bot is a member of
		channels = ("##{channel.name}" for id, channel of slack.channels)
		# Log info to server
		console.log "Welcome to Slack. You are @#{slack.self.name} of #{slack.team.name}"

	#########################
	## SLACK MESSAGE       ##
	#########################

	slack.on 'message', (message) ->

		## Verify message is not a user joining, etc
		if !(_.has(message, 'subtype'))

			## Build info to display in console & display it
			info = {
				channel_id : slack.getChannelGroupOrDMByID(message.channel)
				channel : slack.channels[message.channel]
				sender : slack.users[message.user].name
				text : message.text
				message : message
				image : slack.users[message.user].profile.image_192
			}

			##############################
			## BLOG CHANNEL COMMANDS    ##
			##############################

			blog info, false, () ->
				## Listen for messages in blog channel and save them to RethinkDB

				## Content is equal to slack message text
				content = info.text
				## Image is equal to slack user image
				image = info.image
				## Set time variable to current time
				time = new Date
				## Convert time converted to milliseconds
				now = time.getTime()
				## Convert time to pretty format ex: 7:12 pm
				cleanTime = moment(time).calendar()
				## Author of the slack message
				author = info.sender

				## Insert post into RethinkDB
				r.table('posts').insert([
					{ 
						content: content, 
						time: now, 
						cleanTime: cleanTime 
						image: image,
						author: author
					}
				]).run connection, (err, result) ->
					throw err if err
					## Log info for troubleshooting
					console.log JSON.stringify(result, null, 2)

			#########################
			## COMMANDS            ##
			#########################	

			## Turn the bot off, commands with zombie set to false will not work
			cmd '!off', info, true, () ->
				options.is_running = false
				response = 'Turning off!'
				info.channel_id.send response

			## Turn the bot on
			cmd '!on', info, true, () ->
				options.is_running = true
				response = 'Turning on!'
				info.channel_id.send response
			
			## For testing the bot is working
			cmd '!hi', info, false, () ->
				response = 'Hello'
				info.channel_id.send response

			## Log message info to server
			messageInfo(info)
			return

	slack.on 'error', (err) ->
		console.error "Error", err

	slack.login()