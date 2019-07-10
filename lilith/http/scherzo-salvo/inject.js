document.title = 'Pernacchia';

var x = document.createElement("IMG");
x.setAttribute("src", "http://192.168.6.1/scherzo-salvo/horror.jpg");
x.setAttribute("style", "width:100%; height:100%; position: fixed; top:0; z-index: 999");
window.onload = function() {
	setTimeout(function() {
		document.body.appendChild(x);
	}, 10000);	
}
