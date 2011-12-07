/*
DPS v1.0

Copyright (c) 2011 Owen Winkler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

e=document.createElement('script');e.type='text/javascript';e.src='http://cdnjs.cloudflare.com/ajax/libs/jquery/1.7/jquery.min.js';e.onload=function(){
f=document.createElement('script');f.type='text/javascript';f.src='http://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.8.13/jquery-ui.min.js';f.onload=function(){
	jQuery("<style type='text/css'> .ui-selectable-helper{ border: 1px dotted red;position:absolute;} #page table .ui-selecting {background: orange; border-radius: 0;} </style>").appendTo("head");
	jQuery('table').selectable({
		filter: '.form-option',
		start: function() {
			$('.ui-selectable-helper').css({border: '1px dotted orange', position: 'absolute'});
		},
		selected: function(event, ui) {
		    var $checkbox = $(ui.selected).find(':checkbox');
       		$checkbox.attr('checked', !$checkbox.attr('checked'));
		}
	});	
};document.body.appendChild(f);};document.body.appendChild(e);
