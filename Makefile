inventory_json := inventory.json
apps := $(shell jq -r '"app-" + keys[]' $(inventory_json))

# Don't autoremove any intermediate files; they should be cached.
.SECONDARY:
.PHONY: clean

all: $(apps)

clean:
	rm -rf build dist

$(apps): app-% : \
	dist/icon/16x16/%.png \
	dist/icon/32x32/%.png

build/platforms/android:
	mkdir -p $@

build/platforms/android/%.json: | build/platforms/android
	if [ -s 'static/android/$*.json' ]; then \
		cp 'static/android/$*.json' $@ \
		; \
	else \
		jq -r '.["$*"].platforms.android.package' $(inventory_json) | \
		xargs -I {} curl -sS -4 "https://play.google.com/store/apps/details?id={}&hl=en" | \
		grep -Eo 'class="cover-image" src="([^"]+)"' | cut -c25- | awk '{print "{\"icon\":"$$0"}"}' | jq -S . > $@ \
		; \
	fi

build/platforms/android/%.png: build/platforms/android/%.json | build/platforms/android
	if [ -s 'static/android/$*.png' ]; then \
		cp 'static/android/$*.png' $@ \
		; \
	else \
		jq -r '.icon' $< | xargs -I {} curl -sS -4 -o $@ {} \
		; \
	fi

dist/icon/16x16:
	mkdir -p $@

dist/icon/16x16/%.png: build/platforms/android/%.png | dist/icon/16x16
	gm convert $< -resize 16x16 $@
	pngcrush -q -brute $@ $@.crushed && mv $@.crushed $@

dist/icon/32x32:
	mkdir -p $@

dist/icon/32x32/%.png: build/platforms/android/%.png | dist/icon/32x32
	gm convert $< -resize 32x32 $@
	pngcrush -q -brute $@ $@.crushed && mv $@.crushed $@
