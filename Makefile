BIN=bin

all:
	echo "Run 'make mlton' or 'make smlnj'"
	false

mlton:
	mlton -output $(BIN)/smack smack.mlb

smlnj:
	sml smack.cm # FIXME: This is wrong, I know.

clean:
	rm -f $(BIN)/smack

.PHONY: clean mlton smlnj
