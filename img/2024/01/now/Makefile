ALL += hero.jpg
ALL += plane.jpg
ALL += city.jpg
ALL += box.jpg
ALL += van.jpg
ALL += view.jpg
ALL += car.jpg
ALL += red-rocks-1.jpg
ALL += red-rocks-2.jpg
ALL += red-rocks-3.jpg
ALL += red-rocks-4.jpg
ALL += zion.jpg

all: $(ALL)

clean:
	rm $(ALL)

hero.jpg: orig/PXL_20240106_191954341.jpg
	magick $< -resize 1920x -gravity center -crop 1920x1080+0+0 $@

plane.jpg: orig/PXL_20231101_012852965.NIGHT.jpg
	magick $< -resize 480x $@

city.jpg: orig/PXL_20231103_151152776.jpg
	magick $< -resize 480x $@

box.jpg: orig/PXL_20231029_164529758.jpg
	magick $< -resize 480x $@

van.jpg: orig/PXL_20231111_184838168.jpg
	magick $< -resize 480x $@

view.jpg: orig/PXL_20231114_224146019.jpg
	magick $< -resize 480x $@

car.jpg: orig/PXL_20240104_232707301.PORTRAIT.jpg
	magick $< -resize 480x $@

red-rocks-1.jpg: orig/PXL_20231129_170702411.MP.jpg
	magick $< -resize 480x $@

red-rocks-2.jpg: orig/PXL_20231129_170810590.jpg
	magick $< -resize 480x $@

red-rocks-3.jpg: orig/PXL_20231129_205822721.jpg
	magick $< -resize 480x $@

red-rocks-4.jpg: orig/PXL_20231202_205556855.jpg
	magick $< -resize x640 $@

zion.jpg: orig/PXL_20231206_220934073.MP.jpg
	magick $< -resize 480x $@
