// highlight the code blocks
Prism.highlightAll();

// task elements
const $tasks = $.cls('task');

for (let $task of $tasks) {
	let id = $task.id + '-marked';
	// check if there are marked tasks
	if (localStorage.getItem(id) === 'on')
		$task.classList.toggle('marked');
	else localStorage.setItem(id, 'off');

	// mark the task by right-clicking
  $task.on('contextmenu', function(e) {
    e.preventDefault();
    $task.classList.toggle('marked');
    if (localStorage.getItem(id) == 'on')
    	localStorage.setItem(id, 'off');
    else localStorage.setItem(id, 'on');
  });
}