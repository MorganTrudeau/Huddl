const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database. 
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);



exports.sendRoomMessageNotification = functions.database.ref('Room_Messages/{room}/{message}').onWrite(event => {
 		


 	// The topic name can be optionally prefixed with "/topics/".
	var topic = event.params.room;
	var text = event.data.child('text').val();
	var roomName = event.data.child('room_name').val();
	var senderID = event.data.child('sender_id').val();

	// See the "Defining the message payload" section below for details
	// on how to define a message payload.
	var payload = {
	  notification: {
    		title: "New message in " + roomName,
    		body: text
  		},
  		data: {
  			senderID: senderID,
  			roomID: topic,
  			roomName: roomName
  		}
	};

	// Send a message to devices subscribed to the provided topic.
	admin.messaging().sendToTopic(topic, payload)
	  .then(response => {
	    // See the MessagingTopicResponse reference documentation for the
	    // contents of response.
	    console.log("Successfully sent message:", response);
	    return;
	  })
	  .catch(error => {
	    console.log("Error sending message:", error);
	    return;
	  });
});

exports.sendChatMessageNotification = functions.database.ref('Chat_Messages/{chat}/{message}').onWrite(event => {
 		
 	// The topic name can be optionally prefixed with "/topics/".
	var text = event.data.child('text').val();
	var senderName = event.data.child('sender_name').val();
	var senderID = event.data.child('sender_id').val();
	var chatID = event.params.chat
	var receiverID = event.data.child('receiver_id').val();
	var tokenRef = admin.database().ref('Users/' + receiverID + '/token');

	var payload = {
	  notification: {
    		title: "New message from " + senderName,
    		body: text
  		},
  		data: {
  			senderID: senderID,
  			senderName: senderName,
  			chatID: chatID
  		}
	};

	tokenRef.once('value')
		.then(snapshot => {
			var token = snapshot.val();
			return admin.messaging().sendToDevice(token, payload)
				.then(response => {
				    console.log("Successfully sent message:", response);
				    return;
				})
				.catch(error => {
				    console.log("Error sending message:", error);
				    return;
		  		});
		})
		.catch(error => {
	    	console.log("Error getting token:", error);
	    	return;
	  	});

	// See the "Defining the message payload" section below for details
	// on how to define a message payload.
	

	// Send a message to devices subscribed to the provided topic.
});
