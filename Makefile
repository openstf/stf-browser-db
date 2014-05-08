inventory_json := index.json
store_apps := $(shell jq -r '.[] | .platforms.android | select(. and (.system | not)) | .package' $(inventory_json))

all: $(store_apps)

$(store_apps): % : \
	build/platforms/android/%.json \
	build/platforms/android/%.png \
	dist/icon/16x16/%.png \
	dist/icon/24x24/%.png

build/platforms/android:
	mkdir -p $@

build/platforms/android/%.json: | build/platforms/android
	curl -sS -o $@ https://42matters.com/api/1/apps/lookup.json\?access_token=$(FOURTYTWOMATTERS_APIKEY)\&p=$(shell basename $@ .json)\&lang=en

build/platforms/android/%.png: | build/platforms/android
	curl -sS -o $@ $(shell jq -r '.icon' $(@:.png=.json))

dist/icon/16x16:
	mkdir -p $@

dist/icon/16x16/%.png: build/platforms/android/%.png | dist/icon/16x16
	gm convert $< -resize 16x16 $@
	pngcrush -q -ow -brute $@

dist/icon/24x24:
	mkdir -p $@

dist/icon/24x24/%.png: build/platforms/android/%.png | dist/icon/24x24
	gm convert $< -resize 24x24 $@
	pngcrush -q -ow -brute $@
