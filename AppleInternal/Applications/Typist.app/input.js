var textarea = document.getElementById("typist-input");
var input = document.createElement('input');
input.setAttribute('id', 'typist-input');
input.setAttribute('type', textarea.getAttribute('type'))
input.setAttribute('autocorrect',textarea.getAttribute('autocorrect'));
input.setAttribute('autocapitalize',textarea.getAttribute('autocapitalize'));
input.setAttribute('spellcheck',textarea.getAttribute('spellcheck'));
input.setAttribute('autofocus',true);
input.value = textarea.value;
textarea.parentNode.replaceChild(input, textarea);
