app:
	elm make src/App.elm --output swipe-local-history.js
	
docs:
	elm make --docs=documentation.json
	@echo now upload documentation.json to http://package.elm-lang.org/help/docs-preview

ngrok:
	ngrok http 8088

osxClear:
	/usr/bin/osascript -e 'tell application "System Events" to tell process "Terminal" to keystroke "k" using command down'

clean:
	rm -rf elm-stuff/build-artifacts/0.16.0/user/project/
