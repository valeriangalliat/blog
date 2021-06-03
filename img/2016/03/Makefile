HORIZONTAL = \
	bike/01.jpg bike/02.jpg bike/03.jpg bike/04.jpg \
	mountain/01.jpg mountain/02.jpg mountain/03.jpg mountain/04.jpg \
	mountain/05.jpg mountain/06.jpg mountain/07.jpg mountain/08.jpg \
	mountain/09.jpg mountain/10.jpg mountain/11.jpg mountain/12.jpg \
	ny/01.jpg ny/02.jpg ny/03.jpg ny/04.jpg ny/05.jpg ny/06.jpg

VERTICAL = \
	airport/01.jpg airport/02.jpg \
	bike-2/01.jpg bike-2/02.jpg \
	guitar/01.jpg guitar/02.jpg guitar/03.jpg

HORIZONTAL_THUMB = $(HORIZONTAL:.jpg=.thumb.jpg)
VERTICAL_THUMB = $(VERTICAL:.jpg=.thumb.jpg)

all: $(HORIZONTAL_THUMB) $(VERTICAL_THUMB) busbud.thumb.jpg

%.thumb.jpg: %.jpg
	if echo $(HORIZONTAL) | grep $<; then \
		convert $< -resize 480x360^ -gravity center -extent 480x360 $@; \
	else \
		convert $< -resize 480x640^ -gravity center -extent 480x640 $@; \
	fi

busbud.thumb.jpg: busbud.jpg
	convert $< -resize 1920x $@
