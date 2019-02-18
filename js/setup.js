// adds an 'on' method to all DOM's elements
Node.prototype.on = function(event, cb) {
	this.addEventListener(event, cb);
}

const $ = {};
$.id    = document.getElementById.bind(document);
$.tag   = document.getElementsByTagName.bind(document);
$.cls   = document.getElementsByClassName.bind(document);
$.q     = document.querySelector.bind(document);
$.qAll  = document.querySelectorAll.bind(document);