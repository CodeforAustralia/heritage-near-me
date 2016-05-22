Elm.Native.TimeTask = {};
Elm.Native.TimeTask.make = function(localRuntime) {

	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.TimeTask = localRuntime.Native.TimeTask || {};
	if (localRuntime.Native.TimeTask.values)
	{
		return localRuntime.Native.TimeTask.values;
	}

	var Task = Elm.Native.Task.make(localRuntime);

	var getCurrentTime = Task.asyncFunction(function(callback) {
		return callback(Task.succeed(Date.now()));
	});


	return localRuntime.Native.TimeTask.values = {
		getCurrentTime: getCurrentTime
	};
};
