var fork 	= require('child_process').fork;
var bot 	= fork('./bot');
var server 	= fork('./server');
