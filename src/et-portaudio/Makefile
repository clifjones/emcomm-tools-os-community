CC = gcc
CFLAGS = -Wall -O2
LDFLAGS = -lportaudio -lasound

TARGET = et-portaudio
SRC = main.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

clean:
	rm -f $(TARGET) *.o
