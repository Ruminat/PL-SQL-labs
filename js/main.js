// highlight the code blocks
Prism.highlightAll();

// task elements
const $tasks = $.cls('task');

for (let $task of $tasks) {
	let id = $task.id + '-marked';
  let $contentsTask = $.id('contents-' + $task.id);
	// check if there are marked tasks
	if (localStorage.getItem(id) === 'on') {
    $task.classList.toggle('marked');
    $contentsTask.classList.toggle('marked');
  }
	else localStorage.setItem(id, 'off');

	// mark the task by right-clicking
  $task.on('contextmenu', function(e) {
    e.preventDefault();
    $task.classList.toggle('marked');
    $contentsTask.classList.toggle('marked');
    if (localStorage.getItem(id) == 'on')
    	localStorage.setItem(id, 'off');
    else localStorage.setItem(id, 'on');
  });
}