.PHONY: doc depend

JAZZY_FLAGS = --skip-undocumented -o ../doc
CARTHAGE_FLAGS = --platform iOS --no-use-binaries

doc:
	jazzy $(JAZZY_FLAGS)

depend:
	carthage update $(CARTHAGE_FLAGS)