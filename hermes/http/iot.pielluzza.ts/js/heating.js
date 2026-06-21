/**
 * Display the heater status on the webpage
 */
function putHeaterStatus(heaterName, statusJson)
{
	console.log("putHeaterStatus: " + heaterName + ", " + statusJson);
	statusPh = document.getElementById("stat-" + heaterName);
	statusPh.innerText = statusJson;
}

/**
 * Display the relay status on the webpage
 */
function putRelayStatus(rlyName, state)
{
	console.log("putRelayStatus: " + rlyName + ", " + state);
	statusPh = document.getElementById("rly-" + rlyName);
	statusPh.innerText = state;
}

/*
 * Send mode message to the desired thermostat.
 * Parameters:
 * 	mode  -> mode set value ('A', '0', '1')
 * 	hName -> name of the destination heater
 */
function sendMode(mode, hName) {
	message = new Paho.MQTT.Message(mode);
	message.destinationName = "pielluzza/heating/" + hName + "/set_mode";
	mqtt.send(message);
	console.log("sendMode: " + message.destinationName + " = " + mode);
}

function sendTemp(hName) {
	var inTemp = document.getElementById("inTemp");
	message = new Paho.MQTT.Message(inTemp.value);
	message.destinationName = "pielluzza/heating/" + hName + "/target_temperature";
	mqtt.send(message);
	console.log("sendTemp: " + message.destinationName + " = " + inTemp.value);
}

function onMessageArrived(message) {
	console.log("onMessageArrived: " + message.destinationName
				+ " -> " + message.payloadString);
	
	// message.destination name contains the topic for the received message
	// Split it on '/' to extract the node name and whether it's a relay
	// or heater
	var msgSplit = message.destinationName.split('/');
	var type = msgSplit[1];
	var name = msgSplit[2];
	
	if (type === 'relay')
		putRelayStatus(name, message.payloadString);
	else if (type === 'heating')
		putHeaterStatus(name, message.payloadString);
	else
		console.log("onMessageArrived: unknown type: " + type);
}

/*
 * Subsribe to the MQTT topics of interest:
 * Status messages for relays and heaters
 */
function topicSubscribe() {
	console.log("MQTT connected");
	mqtt.subscribe("pielluzza/heating/+/status");
	mqtt.subscribe("pielluzza/relay/+/status");
}

/* MAIN: */
var mqtt = new Paho.MQTT.Client("iot.pielluzza.ts",9001,"IoTDash");
mqtt.connect({onSuccess:topicSubscribe});
mqtt.onMessageArrived = onMessageArrived;
