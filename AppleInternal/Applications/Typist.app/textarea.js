var input = document.getElementById("typist-input");
var textarea = document.createElement('textarea');
textarea.setAttribute('id', 'typist-input');
textarea.setAttribute('type', input.getAttribute('type'))
textarea.setAttribute('autocorrect',input.getAttribute('autocorrect'));
textarea.setAttribute('autocapitalize',input.getAttribute('autocapitalize'));
textarea.setAttribute('spellcheck',input.getAttribute('spellcheck'));
textarea.setAttribute('autofocus',true);
textarea.value = input.value;
input.parentNode.replaceChild(textarea, input);
textarea.setSelectionRange(textarea.value.length, textarea.value.length);
