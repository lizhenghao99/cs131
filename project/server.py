import asyncio
import aiohttp
import time
import sys
import string
import json

servers = {
    'Goloman':  12166,
    'Hands':    12167,
    'Holiday':  12168,
    'Welsh':    12169,
    'Wilkes':   12170
}

talkswith = {
    'Goloman':  ['Hands', 'Holiday', 'Wilkes'],
    'Hands':    ['Goloman', 'Wilkes'],
    'Holiday':  ['Goloman', 'Welsh', 'Wilkes'],
    'Welsh':    ['Holiday'],
    'Wilkes':   ['Goloman', 'Hands', 'Holiday']
}

connections = []
clients = {}
currentserver = ''
log = None

API_KEY = 'AIzaSyAhseGmLErcdhLgfB6-HCHFaONskmUBri4'
PLACES_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'

async def trywrite(writer, server, msg_out):
    try:
        writer.write(msg_out.encode())
        try:
            reader, writer = await asyncio.open_connection(
            '127.0.0.1', server)
            writer.write(msg_out.encode())
            writer.write_eof()
            await writer.drain() 
            writer.close()
        except(ConnectionError):
            log.write(server + ": unable to connect\n")
    except:
        pass

async def get_location(coor):
    start1 = 0
    end1 = 0
    start2 = 0
    if coor[0] == '+':
        start1 = 1
    else:
        start1 = 0
    for i, c in enumerate(coor[1:]):
        if c == '+':
            end1 = i + 1
            start2 = i + 2
            break
        elif c == '-':
            end1 = i + 1
            start2 = i + 1
            break
        else:
            continue       
    location = coor[start1:end1] + ',' + coor[start2:]
    return location 
    

async def flood(client):
    global log
    global currentserver
    global clients
    global talkswith

    for server in talkswith[currentserver]:
        msg_out = 'INTERNAL {} {} {} {} {}\n'.format(
            client['id'], client['coor'], client['time'],
            client['diff'], client['host'])
        try:
            reader, writer = await asyncio.open_connection(
            '127.0.0.1', servers[server])
            writer.write(msg_out.encode())
            writer.write_eof()
            await writer.drain() 
            writer.close()
            log.write(
                server + ": propagate info for client {}\n".format(
                    client['id']))
        except(ConnectionError):
            log.write(server + ": unable to connect\n")


async def handle_iamat(tokens, msg_out):
    global currentserver
    global clients
    if len(tokens) != 4:
        return msg_out
    else:
        mytime = time.time() - float(tokens[3])
        if mytime > 0:
            timestring = '+{0:.9f}'.format(mytime)
        else:
           timestring = str(mytime)
        # message out    
        msg_out = 'AT {} {} {} {} {}\n'.format(
            currentserver, timestring, tokens[1], tokens[2], tokens[3]
        ) 
        # update client to database
        client = {
           'id':   tokens[1],
            'coor': tokens[2],
            'time': tokens[3],
            'diff': timestring,
            'host': currentserver
        }
        if client['id'] not in clients:
            clients[client['id']] = client
        else:
            if client['time'] > clients[client['id']]['time']:
                clients[client['id']] = client

        # flood to other servers
        await flood(client)
        # return message
        return msg_out

async def handle_whatsat(tokens, msg_out):
    global currentserver
    global clients
    global log
    if len(tokens) != 4:
        return msg_out
    else:
        if tokens[1] not in clients:
            return msg_out
        else:
            msg_out = 'AT {} {} {} {} {}\n'.format(
                clients[tokens[1]]['host'],
                clients[tokens[1]]['diff'],
                clients[tokens[1]]['id'],
                clients[tokens[1]]['coor'],
                clients[tokens[1]]['time']
            )
            
            location = await get_location(clients[tokens[1]]['coor'])

            log.write('Contacting Google Places for client {}\n'.format(
                clients[tokens[1]]['id']))

            jsonstring = ''
            async with aiohttp.ClientSession() as session:
                params = [('location', location),
                          ('radius', tokens[2]+'000'),
                          ('key', API_KEY)]
                async with session.get(PLACES_URL, params=params) as resp:
                    jsonstring = await resp.text()
            
            resultcap = int(tokens[3])
            jsonobject = json.loads(jsonstring)
            if len(jsonobject['results']) > resultcap:
                jsonobject['results'] = jsonobject['results'][:resultcap]
            jsontrimmed = json.dumps(jsonobject, indent=3)

            msg_out += jsontrimmed + '\n\n'

            return msg_out

async def handle_internal(tokens, msg_out):
    global clients
    client = {
        'id':   tokens[1],
        'coor': tokens[2],
        'time': tokens[3],
        'diff': tokens[4],
        'host': tokens[5]
    }
    msg_out = None
    if client['id'] not in clients:
        clients[client['id']] = client
        await flood(client)
    else:
        if client['time'] > clients[client['id']]['time']:
            clients[client['id']] = client
            await flood(client)
        else:
            pass
    return msg_out

async def handle_message(msg_in):
    global currentserver
    global clients

    msg_in = msg_in.strip()
    msg_out = '? ' + msg_in + '\n'
    
    tokens = msg_in.split()
    if len(tokens) < 1:
        return msg_out

    # IAMAT
    if tokens[0] == 'IAMAT':
        return await handle_iamat(tokens, msg_out)
    # WHATSAT
    elif tokens[0] == 'WHATSAT':
        return await handle_whatsat(tokens, msg_out)
    # INTERNAL
    elif tokens[0] == 'INTERNAL':
        await handle_internal(tokens, msg_out)
    # invalid 
    else:
        return msg_out
    

async def handle_connection(reader, writer): 
        data = await reader.read()
        msg_in = data.decode()

        global log
        if msg_in.endswith('\n'):
            log.write('RECEIVED: {}'.format(msg_in))
        else:
            log.write('RECEIVED: {}\n'.format(msg_in))

        msg_out = await handle_message(msg_in)

        if msg_out != None:
            log.write('RESPONDED: {}'.format(msg_out))
            writer.write(msg_out.encode())
        writer.write_eof()
        await writer.drain() 
        writer.close()

async def main():
    global servers
    # test for argc
    if len(sys.argv) < 2:
        print('Error: requires server name')
        exit()
    # get server name
    global currentserver
    currentserver = sys.argv[1]
    if currentserver not in servers:
        print('Error: invalid server name')
        exit()
    # open logfile
    global log
    logfile = currentserver + '-log.txt'
    log = open(logfile, 'w')
    log.write('Running on ' + currentserver + '\n\n')
    # run server
    server = await asyncio.start_server(
        handle_connection, host='127.0.0.1', port=servers[currentserver]) 
    await server.serve_forever()

if __name__ == '__main__': 
    asyncio.run(main())