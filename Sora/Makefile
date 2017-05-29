.phony: archive clean

ARCHIVE=Sora.framework.zip

archive:
	carthage build --no-skip-current
	carthage archive Sora

clean:
	rm $(ARCHIVE)
