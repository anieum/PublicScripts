# PublicScripts

Here I will place some of the things I wrote and found useful for myself.


# Themes
For browser themes use either greasemonkey to make them permanent or use bookmarklets. I recommend this for instance: https://caiorss.github.io/bookmarklet-maker/

## Artemis White
----
This doesn't actually change any colors, but it swaps the font, increases its size and centers content to make the excercise page more readable.

![A artemis theme](Screenshots/artemis_white.png)

Bookmarklet: <a href="javascript:(function()%7Bb%20%3D%20document.body.style%3B%0Ab.transition%20%3D%20%221s%22%3B%0Ab.fontFamily%20%3D%20%22Minion%20Pro%22%3B%0Ab.fontSize%20%3D%20%221.2rem%22%3B%0Ai%20%3D%20document.getElementById(%22programming-exercise-instructions-content%22).style%3B%0Ai.maxWidth%20%3D%20%2250rem%22%3B%0Ai.margin%20%3D%20%22auto%22%3B%7D)()%3B">Artemis White</a>


## Artemis Dark
----
![A dark artemis theme](Screenshots/artemis_black.png)

Bookmarklet: <a href="javascript:(function()%7Bb%20%3D%20document.body.style%3B%0Ab.transition%20%3D%20%221s%22%3B%0Ab.fontFamily%20%3D%20%22Minion%20Pro%22%3B%0Ab.fontSize%20%3D%20%221.2rem%22%3B%0Ab.color%20%3D%20%22%23d4d4d4%22%0Ai%20%3D%20document.getElementById(%22programming-exercise-instructions-content%22).style%3B%0Ai.maxWidth%20%3D%20%2250rem%22%3B%0Ai.margin%20%3D%20%22auto%22%3B%7D)()%3B">Artemis Dark</a>

The colors are mostly from VSCode as it already uses a dark theme with well balanced colors.

