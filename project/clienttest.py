import asyncio
import time

async def first():
    try:
        reader, writer = await asyncio.open_connection('127.0.0.1', 12166) 
    except(ConnectionError):
        print("Connection failed")
        return
    writer.write(
        "IAMAT kiwi.cs.ucla.edu +30.068930-110.445127 {0:.9f}".format(time.time()).encode())
    writer.write_eof()
    data = await reader.read() 
    print('{}'.format(data.decode()), end='')
    writer.close()

async def second():
    try:
        reader, writer = await asyncio.open_connection('127.0.0.1', 12167) 
    except(ConnectionError):
        print("Connection failed")
        return
    writer.write(
         "IAMAT kiwi.cs.ucla.edu +34.068930-118.445127 {0:.9f}".format(time.time()).encode())
    writer.write_eof()
    data = await reader.read() 
    print('{}'.format(data.decode()), end='')
    writer.close()

async def third():
    try:
        reader, writer = await asyncio.open_connection('127.0.0.1', 12168) 
    except(ConnectionError):
        print("Connection failed")
        return
    writer.write(
        "IAMAT eric.cs.ucla.edu +40.758895-73.985131 {0:.9f}".format(time.time()).encode())
    writer.write_eof()
    data = await reader.read() 
    print('{}'.format(data.decode()), end='')
    writer.close()

async def fourth():
    try:
        reader, writer = await asyncio.open_connection('127.0.0.1', 12169) 
    except(ConnectionError):
        print("Connection failed")
        return
    writer.write(
        "WHATSAT kiwi.cs.ucla.edu 10 5".encode())
    writer.write_eof()
    data = await reader.read() 
    print('{}'.format(data.decode()), end='')
    writer.close()

async def fifth():
    try:
        reader, writer = await asyncio.open_connection('127.0.0.1', 12170) 
    except(ConnectionError):
        print("Connection failed")
        return
    writer.write(
        "WHATSAT eric.cs.ucla.edu 1 2".encode())
    writer.write_eof()
    data = await reader.read() 
    print('{}'.format(data.decode()), end='')
    writer.close()

async def main():
    await first()
    await second()
    await third()
    await fourth()
    await fifth()

if __name__ == "__main__":
    asyncio.run(main())