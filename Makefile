inventory_json := inventory.json
apps := $(shell jq -r '"app-" + keys[]' $(inventory_json))

# Don't autoremove any intermediate files; they should be cached.
.SECONDARY:

all: $(apps)

$(apps): app-% : \
	dist/icon/16x16/%.png \
	dist/icon/24x24/%.png

build/platforms/android:
	mkdir -p $@

build/platforms/android/%.json: | build/platforms/android
	if [ -f 'static/android/$*.json' ]; then \
		cp 'static/android/$*.json' $@ \
		; \
	else \
		jq -r '.["$*"].platforms.android.package' $(inventory_json) | \
		xargs -I {} curl -sS "https://42matters.com/api/1/apps/lookup.json?access_token=$(FOURTYTWOMATTERS_APIKEY)&p={}&lang=en" | jq -S . > $@ \
		; \
	fi

build/platforms/android/%.png: build/platforms/android/%.json | build/platforms/android
	if [ -f 'static/android/$*.png' ]; then \
		cp 'static/android/$*.png' $@ \
		; \
	else \
		jq -r '.icon' $< | xargs -I {} curl -sS -o $@ {} \
		; \
	fi

dist/icon/16x16:
	mkdir -p $@

dist/icon/16x16/%.png: build/platforms/android/%.png | dist/icon/16x16
	gm convert $< -resize 16x16 $@
	pngcrush -q -brute $@ $@.crushed && mv $@.crushed $@

dist/icon/24x24:
	mkdir -p $@

dist/icon/24x24/%.png: build/platforms/android/%.png | dist/icon/24x24
	gm convert $< -resize 24x24 $@
	pngcrush -q -brute $@ $@.crushed && mv $@.crushed $@
