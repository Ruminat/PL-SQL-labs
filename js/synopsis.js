// task elements
const $sections = $.cls('section-link');

console.log($sections);
console.log($menu);

for (let $section of $sections) {
  let $element = document.createElement('a');
  $element.className = 'element';
  $element.href = '#'+ $section.id;
  
  let $iconPart = document.createElement('div');
  $iconPart.className = 'icon-part';
  $iconPart.innerText = /\d+$/.exec($section.id)[0] +'.';
  let $textPart = document.createElement('div');
  $textPart.className = 'text-part';
  $textPart.innerText = $section.innerText.replace(/^\d+\. /, '');

  $element.appendChild($iconPart);
  $element.appendChild($textPart);

  $menu.appendChild($element);
}