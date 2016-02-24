var total_messages = 5;
var delay_amount = 0;
var fade_speed = 200;
var socket = io();

// Connect to Socket.io
socket.connect('http://localhost:4567/');

// Handle event with new post 
socket.on('new post', function(json) {
	// Get oldest post to remove later if needed
	var oldest_post = $('.message').first();
	// Get count of posts before appending another
	var count = $('.message').length;

	// Remove oldest post from the DOM
	function removePost() {
		// Fade post out
		oldest_post.animate({
			opacity: 0
		}, fade_speed, function() {
			// Remove post from DOM
			oldest_post.remove();
		});
	}

	// Add new post to the DOM
	function addPost() {
		// Construct HTML to append
		$('.messages').append($(msg_start + msg_time + msg_img + msg_info + msg_end));
		// Fade post in
		$('.message').last().animate({
			opacity: 1
		}, fade_speed, function() {
			// Animation is complete
		});
	}

	// If there are more than `total_messages`, start removing from top
	if ( count >= total_messages ) { 
		// Delay for fading elements in and out
		delay_amount = fade_speed + 1;
		// Remove the post from the DOM
		removePost();
	}

	var parsed = JSON.parse(json);
	var msg_start = '<article class="message" style="opacity:0;">'+parsed.new_val.content;
	var msg_time = '<span class="time">'+moment(parsed.new_val.time).calendar()+'</span>';
	var msg_img = '<span class="image"><img src="'+parsed.new_val.image+'" alt="Profile Image"></span>';
	var msg_info = '<span class="info">'+parsed.new_val.author+'</span>';
	var msg_end = '</article>';

	// Delay adding post to allow fading of deleted array
	setTimeout(function() {
		addPost();
	}, delay_amount)
});